import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import 'package:googleapis/drive/v3.dart' as drive;
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;

import '../../../firebase_options.dart';
import '../../../l10n/strings.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/helper.dart';
import '../../login_screen.dart';

// Android service channel for foreground recording
const _recSvc = MethodChannel('study_buddy/recorder_service');


// OUTSIDE the State class: small HTTP client wrapper for Google APIs.
class _GoogleAuthClient extends http.BaseClient {
  final Map<String, String> _headers;
  final http.Client _client = http.Client();

  _GoogleAuthClient(this._headers);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.addAll(_headers);
    return _client.send(request);
  }

  void close() => _client.close();
}

class RecorderPage extends StatefulWidget {
  const RecorderPage({super.key});
  @override
  State<RecorderPage> createState() => _RecorderPageState();
}

class _RecorderPageState extends State<RecorderPage> {
  // Focus node for topic field
  final FocusNode _topicFocus = FocusNode();

  // Tracks if user selected from dropdown (existing class)
  bool _selectedExistingClass = false;

  // Controllers
  final TextEditingController _classCtl = TextEditingController();
  final TextEditingController _topicCtl = TextEditingController();

  // Recording state
  final AudioRecorder _recorder = AudioRecorder();
  Timer? _ticker;
  String? _filePath;
  bool _isRecording = false;
  bool _isPaused = false;
  bool _recordingComplete = false;
  int _elapsedSeconds = 0;

  // Re-enable service by default (baseline behavior). Set to true only for debugging.
  static const bool _debugForcePluginRecorder = false;

  // Upload state
  bool _isUploading = false;
  double? _uploadProgress; // 0..1 or null for indeterminate
  String? _uploadPhase; // 'Firebase' | 'Google Drive'

  // Google Sign-In (kept here so Drive calls can reuse silently)
  final GoogleSignIn _gsi = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope, 'email'],
  );

  // UI strings (now localized)
  String get _titleText {
    final strings = SBStrings.of(context);
    if (_recordingComplete) return strings.recordingComplete;
    if (_isRecording) return strings.recording;
    return strings.readyToRecord;
  }

  String get _clockText => formatDuration(Duration(seconds: _elapsedSeconds));

  String get _helperText {
    final strings = SBStrings.of(context);
    if (_isUploading) return strings.uploading;
    if (_recordingComplete) return strings.chooseUploadOrDiscard;
    if (_isRecording && _isPaused) return strings.recordingPaused;
    if (_isRecording) return strings.tapRedToStop;
    return strings.enterClassAndTopic;
  }

  bool get _isReadyToRecord =>
      !_isRecording &&
          _classCtl.text.trim().isNotEmpty &&
          _topicCtl.text.trim().isNotEmpty;

  // Fetch distinct class names from Firestore for this user
  Future<List<String>> _fetchClassNames() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) return [];
    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('recordings')
        .get();


    final classes = snap.docs
        .map((d) => (d['className'] ?? '').toString().trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return classes;
  }

  @override
  void initState() {
    super.initState();
    _classCtl.addListener(_recomputeReady);
    _topicCtl.addListener(_recomputeReady);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _classCtl.dispose();
    _topicCtl.dispose();
    super.dispose();
  }

  void _recomputeReady() {
    if (mounted) setState(() {});
  }

  Future<void> _logout() async {
    try {
      await FirebaseAuth.instance.signOut();
      try {
        final acc = await _gsi.signInSilently();
        if (acc != null) {
          await _gsi.signOut();
          try {
            await _gsi.disconnect();
          } catch (_) {}
        }
      } catch (_) {}
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Logged out')),
      );
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginScreen()),
            (_) => false,
      );
    } catch (_) {}
  }

  // ---------------- Recording controls ----------------

  /// Polls for file existence & growth to confirm a recorder actually started.
  Future<bool> _confirmFileAppearsAndGrows(String path,
      {Duration timeout = const Duration(seconds: 3)}) async {
    final f = File(path);
    final start = DateTime.now();
    int lastLen = -1;
    while (DateTime.now().difference(start) < timeout) {
      if (await f.exists()) {
        final len = await f.length();
        if (len > 0 && len != lastLen) {
          lastLen = len;
          await Future.delayed(const Duration(milliseconds: 150));
          final len2 = await f.length();
          if (len2 > len) return true;
        }
      }
      await Future.delayed(const Duration(milliseconds: 120));
    }
    return false;
  }

  Future<void> _startRecording() async {
    appLogger('Record button pressed');
    final perm = await _recorder.hasPermission();
    if (!perm) {
      appLogger('Microphone permission missing/denied');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission denied')),
        );
      }
      return;
    }

    final tmp = await getTemporaryDirectory();
    final fname = fileNameFormatted(
      className: _classCtl.text,
      topic: _topicCtl.text,
      when: DateTime.now(),
    );
    final path = '${tmp.path}/$fname';

    await WakelockPlus.enable(); // keep screen on while recording

    bool started = false;
    bool usedService = false;

    if (Platform.isAndroid && !_debugForcePluginRecorder) {
      try {
        appLogger('Trying to start Android foreground service...');
        final result =
        await _recSvc.invokeMethod('startService', {'path': path});
        appLogger('startService result: $result');
        usedService = true;
        started = await _confirmFileAppearsAndGrows(path);
        appLogger('Service start verified=$started');
      } catch (e) {
        appLogger('startService failed: $e');
        usedService = false;
        started = false;
      }
    } else if (Platform.isAndroid) {
      appLogger('Bypassing Android service (debug flag ON) → using plugin');
    }

    if (!started) {
      appLogger('Falling back to record plugin start');
      try {
        final config = RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
          numChannels: 1, // force mono for broad compatibility
        );
        await _recorder.start(config, path: path);
        started = true;
      } catch (e) {
        appLogger('record.start failed: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Could not start recording: $e')),
          );
        }
        await WakelockPlus.disable();
        return;
      }
    }

    setState(() {
      _filePath = path;
      _isRecording = started;
      _isPaused = false;
      _recordingComplete = false;
      _elapsedSeconds = 0;
    });
    _recomputeReady();

    if (!started) {
      appLogger('Recording was not started (unexpected).');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recording did not start')),
        );
      }
      await WakelockPlus.disable();
      return;
    }

    appLogger('Recording started. mode=${usedService ? 'service' : 'plugin'} path=$path');

    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _isRecording && !_isPaused) {
        setState(() => _elapsedSeconds += 1);
      }
    });
  }

  Future<void> _pauseOrResume() async {
    if (!_isRecording) return;
    appLogger('Pause/Resume tapped. paused=$_isPaused');

    if (Platform.isAndroid) {
      try {
        await _recSvc.invokeMethod(_isPaused ? 'resumeService' : 'pauseService');
        setState(() => _isPaused = !_isPaused);
        appLogger('Service ${_isPaused ? 'paused' : 'resumed'}');
        return;
      } catch (e) {
        appLogger('Service pause/resume failed: $e -> falling back to plugin toggle');
      }
    }

    try {
      if (_isPaused) {
        await _recorder.resume();
      } else {
        await _recorder.pause();
      }
      setState(() => _isPaused = !_isPaused);
      appLogger('Plugin ${_isPaused ? 'paused' : 'resumed'}');
    } catch (e) {
      appLogger('Pause/resume error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pause/Resume failed: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    appLogger('Stop tapped');
    try {
      String? path = _filePath;
      if (Platform.isAndroid) {
        try {
          await _recSvc.invokeMethod('stopService');
          appLogger('Service stopped');
        } catch (e) {
          appLogger('Service stop failed: $e -> trying plugin stop');
          try {
            path = await _recorder.stop();
          } catch (_) {}
        }
      } else {
        path = await _recorder.stop();
        appLogger('Plugin stopped, path=$path');
      }

      _ticker?.cancel();
      setState(() {
        _isRecording = false;
        _isPaused = false;
        _recordingComplete = true;
        if (path != null) _filePath = path;
      });
    } finally {
      await WakelockPlus.disable();
      _recomputeReady();
    }
  }

  // ---------------- Upload flow ----------------

  Future<void> _uploadRecording() async {
    if (_filePath == null) return;

    final fileOnDisk = File(_filePath!);
    if (!await fileOnDisk.exists()) {
      appLogger('Upload requested but file missing: $_filePath');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File missing')),
      );
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
      _uploadPhase = 'Firebase';
    });

    // Ensure Firebase is initialized and user is authenticated
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      appLogger('No authenticated user. Aborting upload.');
      return;
    }
    final uid = user.uid;

    final createdAt = DateTime.now();
    final filename = path.basename(_filePath!);

    // ✅ Ensure the file is fully finalized before ANY upload
    try {
      await _ensureFinalizedRecording(fileOnDisk);
    } catch (e) {
      appLogger('Recording not ready for upload: $e');
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = null;
          _uploadPhase = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Recording not usable: $e')),
        );
      }
      return;
    }

    // Upload to Firebase Storage using the new helper
    try {
      await uploadRecording(fileOnDisk, uid);
    } catch (e) {
      appLogger('Firebase upload failed for path=recordings/$uid/$filename: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Firebase upload failed: $e')),
        );
      }
      setState(() {
        _isUploading = false;
        _uploadProgress = null;
        _uploadPhase = null;
      });
      return;
    }

    // Now Google Drive — upload the original .m4a
    setState(() {
      _uploadPhase = 'Google Drive';
      _uploadProgress = null; // indeterminate for Drive
    });

    // Ensure file length is stable (Android MediaRecorder finalization safety)
    await _waitForStableFileLength(fileOnDisk);

    // Upload original .m4a to Drive (no conversion)
    File driveFile = fileOnDisk;
    String driveFilename = filename;

    String? driveId;
    try {
      driveId = await _uploadToGoogleDriveWithFolders(
        fileOnDisk: driveFile,
        filename: driveFilename,
        className: _classCtl.text,
        topic: _topicCtl.text,
        createdAt: createdAt,
      );
      appLogger('Drive upload ok. fileId=$driveId');
    } catch (e) {
      appLogger('Drive upload failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Drive upload failed: $e')),
        );
      }
    }

    // Firestore metadata (kept as before, with additive fields)
    final durationSeconds = _elapsedSeconds;
    final fileLen = await fileOnDisk.length();
    try {
      await _writeFirestoreMetadata(
        filename: filename,
        className: _classCtl.text,
        topic: _topicCtl.text,
        createdAt: createdAt,
        durationSeconds: durationSeconds,
        storageUrl: "", // Storage URL retrieval omitted in new helper; add if needed
        storagePath: "recordings/$uid/$filename",
        driveFileId: driveId,
        sizeBytes: fileLen,
        mimeType: 'audio/mp4',
      );
      appLogger('Firestore metadata written');
    } on FirebaseException catch (e) {
      appLogger('Firestore write failed (${e.code}): ${e.message}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Firestore write failed: ${e.message}')),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isUploading = false;
        _uploadProgress = null;
        _uploadPhase = null;
      });
      // Clear class/topic inputs and reset selected class state
      _classCtl.clear();
      _topicCtl.clear();
      _selectedExistingClass = false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload complete. Ready for your next lecture!')),
      );
    }

    // Cleanup local file
    await _safeDeleteLocal(fileOnDisk);
    appLogger('Local file deleted');

    // Reset UI to fresh state
    if (mounted) {
      setState(() {
        _filePath = null;
        _recordingComplete = false;
        _elapsedSeconds = 0;
      });
    }
  }

  Future<void> uploadRecording(File file, String uid) async {
    // Ensure Firebase initialized and user authenticated
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user for upload');

    // We no longer read or use academic level/term for building the storage path.
    // This restores the original upload structure where files are stored directly
    // under recordings/{uid}/{filename}. Reading academic settings can be added
    // separately without influencing the storage path.

    final fileName = path.basename(file.path);
    // Upload under recordings/{uid}/{fileName} with no intermediate level/term.
    final storagePath = "recordings/$uid/$fileName";
    appLogger("Uploading to Firebase Storage path=$storagePath");

    final storageRef = FirebaseStorage.instance.ref().child(storagePath);
    await storageRef.putFile(
      file,
      SettableMetadata(contentType: 'audio/mp4'),
    );

    // Save metadata to Firestore. Use className and topic if available via
    // outer context (e.g. passed in from the recording page) instead of level/term.
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('recordings')
        .add({
      'filename': fileName,
      'storagePath': storagePath,
      'createdAt': FieldValue.serverTimestamp(),
      'uid': uid,
    });
  }

  Future<void> _discardRecording() async {
    if (_filePath != null) {
      await _safeDeleteLocal(File(_filePath!));
      appLogger('Recording discarded & local file removed');
    }
    if (mounted) {
      setState(() {
        _filePath = null;
        _recordingComplete = false;
        _elapsedSeconds = 0;
      });
    }
  }

  Future<void> _safeDeleteLocal(File f) async {
    try {
      if (await f.exists()) await f.delete();
    } catch (_) {}
  }

  // ✅ NEW: finalize + minimum-size guard to prevent empty/corrupt uploads
  Future<void> _ensureFinalizedRecording(File f) async {
    final len = await _waitForStableFileLength(f);
    appLogger('Finalized file length before upload: $len bytes');
    if (len < 4096) {
      // ~4 KB guard to catch empty/corrupt recordings
      throw 'Recording looks empty or corrupt (size $len bytes). Please record again.';
    }
  }

  Future<void> _writeFirestoreMetadata({
    required String filename,
    required String className,
    required String topic,
    required DateTime createdAt,
    required int durationSeconds,
    required String storageUrl,
    required String storagePath,
    required String? driveFileId,
    int? sizeBytes,            // NEW optional
    String? mimeType,          // NEW optional
  }) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final meta = <String, dynamic>{
      'filename': filename,
      'className': className,
      'topic': topic,
      'createdAt': createdAt.toIso8601String(),
      'durationSeconds': durationSeconds,
      'storageUrl': storageUrl,
      'storagePath': storagePath,
      'driveFileId': driveFileId,
      'uid': uid,

      // Phase-2 additive fields (non-breaking)
      'transcriptStatus': 'none',
      'transcribeRequested': false,
      'transcriptDriveFileId': null,
      'subtitleDriveFileIds': <String>[],
      'summaryStatus': 'none',
      'notesStatus': 'none',
      'quizStatus': 'none',
    };
    if (sizeBytes != null) meta['sizeBytes'] = sizeBytes;
    if (mimeType != null) meta['mimeType'] = mimeType;
    if (uid == null) throw 'No authenticated user';
    await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('recordings')
        .add(meta);
  }

  // -------- Google Drive helpers --------

  // Small helper to compute semester string safely
  String _semesterFor(DateTime dt) {
    final m = dt.month;
    if (m >= 1 && m <= 5) return 'Spring';
    if (m >= 6 && m <= 8) return 'Summer';
    return 'Fall';
  }

  Future<int> _waitForStableFileLength(
      File f, {
        Duration timeout = const Duration(seconds: 15),
        Duration pollEvery = const Duration(milliseconds: 250),
        int stableReadsRequired = 5,
      }) async {
    int last = -1;
    int stableReads = 0;
    final start = DateTime.now();

    while (DateTime.now().difference(start) < timeout) {
      final len = await f.length();
      if (len == last) {
        stableReads++;
        if (stableReads >= stableReadsRequired) {
          await Future.delayed(const Duration(milliseconds: 300));
          final confirm = await f.length();
          if (confirm == len) return len;
          stableReads = 0;
          last = confirm;
          continue;
        }
      } else {
        stableReads = 0;
        last = len;
      }
      await Future.delayed(pollEvery);
    }
    return await f.length();
  }

  Future<String?> _uploadToGoogleDriveWithFolders({
    required File fileOnDisk,
    required String filename,
    required String className,
    required String topic,
    required DateTime createdAt,
  }) async {
    // Sign in (silently first)
    GoogleSignInAccount? acc = await _gsi.signInSilently();
    acc ??= await _gsi.signIn();
    if (acc == null) throw 'Google Sign-In failed';

    final authHeaders = await acc.authHeaders;
    final httpClient = _GoogleAuthClient(authHeaders);

    try {
      final api = drive.DriveApi(httpClient);

      // Build/ensure folder chain:
      // Study Buddy / {Year}_{Semester} / {Class Name} / {Lecture Topic}
      final rootFolderId =
      await _getOrCreateFolder(api, 'Study Buddy', parentId: 'root');
      final sem = _semesterFor(createdAt);
      final yearSem = '${createdAt.year}_$sem';
      final yearFolderId =
      await _getOrCreateFolder(api, yearSem, parentId: rootFolderId);
      final classFolderId =
      await _getOrCreateFolder(api, className, parentId: yearFolderId);
      final topicFolderId =
      await _getOrCreateFolder(api, topic, parentId: classFolderId);

      // Ensure filesystem has fully flushed/closed the file & stream exact bytes
      final finalLength = await fileOnDisk.length();
      final stream = fileOnDisk.openRead(0, finalLength);

      final meta = drive.File()
        ..name = filename
        ..parents = [topicFolderId];
      if (filename.toLowerCase().endsWith('.mp3')) {
        meta.mimeType = 'audio/mpeg';
      } else if (filename.toLowerCase().endsWith('.m4a')) {
        meta.mimeType = 'audio/mp4';
      }

      // Resumable upload — reliable for large recordings
      final media = drive.Media(stream, finalLength);
      final uploaded = await api.files.create(
        meta,
        uploadMedia: media,
        uploadOptions: drive.ResumableUploadOptions(),
      );

      return uploaded.id;
    } finally {
      httpClient.close(); // close only after the upload is done
    }
  }

  Future<String> _getOrCreateFolder(
      drive.DriveApi api,
      String name, {
        required String parentId,
      }) async {
    final q =
        "mimeType='application/vnd.google-apps.folder' and name='${_escapeForDriveQuery(name)}' and '$parentId' in parents and trashed=false";
    final res = await api.files.list(
      q: q,
      $fields: 'files(id,name)',
      spaces: 'drive',
      pageSize: 1,
    );
    if (res.files != null && res.files!.isNotEmpty) {
      return res.files!.first.id!;
    }
    final folderMeta = drive.File()
      ..name = name
      ..mimeType = 'application/vnd.google-apps.folder'
      ..parents = [parentId];
    final created = await api.files.create(folderMeta);
    return created.id!;
  }

  String _escapeForDriveQuery(String name) => name.replaceAll("'", r"\'");

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final big = min(w * 0.6, 300.0);

    final strings = SBStrings.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          strings.appTitle,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return RefreshIndicator(
            onRefresh: _fetchClassNames,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: 16 + MediaQuery.of(context).padding.bottom,
              ),
              physics: constraints.maxHeight < 700
                  ? const AlwaysScrollableScrollPhysics()
                  : const NeverScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        const SizedBox(height: 8),
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              _titleText,
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _clockText,
                              style: const TextStyle(
                                fontSize: 22,
                                color: Colors.black54,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _helperText,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Inputs
                        FutureBuilder<List<String>>(
                          future: _fetchClassNames(),
                          builder: (context, snapshot) {
                            final classList = snapshot.data ?? [];
                            // Determine dropdown value
                            String? dropdownValue = classList.contains(_classCtl.text) ? _classCtl.text : null;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (snapshot.connectionState == ConnectionState.waiting)
                                  const LinearProgressIndicator(minHeight: 2),
                                DropdownButtonFormField<String>(
                                  value: dropdownValue,
                                  decoration: InputDecoration(
                                    labelText: strings.selectClass,
                                    border: const OutlineInputBorder(),
                                  ),
                                  items: classList
                                      .map((name) => DropdownMenuItem(
                                    value: name,
                                    child: Text(name),
                                  ))
                                      .toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      if (val != null) {
                                        _selectedExistingClass = true;
                                        _classCtl.text = val;
                                        // Focus the topic field
                                        FocusScope.of(context).requestFocus(_topicFocus);
                                      } else {
                                        // Cleared dropdown selection
                                        _selectedExistingClass = false;
                                        _classCtl.clear();
                                      }
                                    });
                                  },
                                  isExpanded: true,
                                ),
                                const SizedBox(height: 6),
                                if (!_selectedExistingClass)
                                  TextField(
                                    controller: _classCtl,
                                    enabled: !_isRecording && !_isUploading && !_recordingComplete,
                                    decoration: InputDecoration(
                                      labelText: strings.enterNewClass,
                                      border: const OutlineInputBorder(),
                                    ),
                                  ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _topicCtl,
                          focusNode: _topicFocus,
                          enabled: !_isRecording && !_isUploading && !_recordingComplete,
                          decoration: InputDecoration(
                            labelText: strings.lectureTopic,
                            border: const OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Record / Stop
                        SizedBox(
                          width: big,
                          height: big,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: const CircleBorder(),
                              backgroundColor: (_isRecording || _isReadyToRecord)
                                  ? (_isRecording ? Colors.red : Colors.deepPurple.shade600)
                                  : Colors.grey[400],
                            ),
                            onPressed: _isRecording
                                ? _stopRecording
                                : (_isReadyToRecord ? _startRecording : null),
                            child: Text(
                              _isRecording ? strings.stop : strings.record,
                              style: const TextStyle(color: Colors.white, fontSize: 22),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Pause / Resume
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isRecording ? _pauseOrResume : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isRecording
                                  ? Colors.grey.shade800
                                  : Colors.grey.shade300,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: Text(
                              _isRecording
                                  ? (_isPaused ? strings.resume : strings.pause)
                                  : strings.pause,
                              style: TextStyle(
                                color: _isRecording
                                    ? Colors.white
                                    : Colors.grey.shade600,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        // Upload progress
                        if (_isUploading) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_uploadProgress == null)
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                ),
                              const SizedBox(width: 8),
                              Text(
                                _uploadPhase == null
                                    ? strings.uploading
                                    : strings.uploadingTo(_uploadPhase!),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          if (_uploadProgress != null)
                            LinearProgressIndicator(
                                value: _uploadProgress, minHeight: 6),
                        ],

                        // Upload / Discard
                        if (_recordingComplete) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isUploading ? null : _uploadRecording,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepPurple.shade600,
                                    padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  child: Text(strings.upload),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isUploading ? null : _discardRecording,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                    padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                  ),
                                  child: Text(strings.discard),
                                ),
                              ),
                            ],
                          ),
                        ],

                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}