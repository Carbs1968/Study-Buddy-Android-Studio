// lib/main.dart

// Dart
import 'dart:async';
import 'dart:io';
import 'dart:math';

// Flutter
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// Plugins
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Google Sign-In / Drive
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis/drive/v3.dart' as drive;

// Platform
import 'dart:io' show Platform;

// Android service channel for foreground recording
const _recSvc = MethodChannel('study_buddy/recorder_service');

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Study Buddy',
      theme: ThemeData(
        colorSchemeSeed: Colors.deepPurple,
        useMaterial3: true,
      ),
      home: const AuthGate(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<fb.User?>(
      stream: fb.FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (snap.data == null) return const LoginPage();
        return const RecorderPage();
      },
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _loading = false;
  String? _error;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final gsi = GoogleSignIn(scopes: [
        drive.DriveApi.driveFileScope,
        'email',
      ]);
      GoogleSignInAccount? acc = await gsi.signIn();
      if (acc == null) throw 'Sign-in canceled';

      final auth = await acc.authentication;
      final credential = fb.GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );
      await fb.FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final btnW = min(w * 0.8, 340.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Buddy'),
        centerTitle: false,
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_error != null) ...[
                  Text(_error!,
                      style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: btnW,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _signInWithGoogle,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 16),
                    ),
                    child: _loading
                        ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                        : const Text('Sign in with Google'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class RecorderPage extends StatefulWidget {
  const RecorderPage({super.key});
  @override
  State<RecorderPage> createState() => _RecorderPageState();
}

class _RecorderPageState extends State<RecorderPage> {
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

  // Upload state
  bool _isUploading = false;
  double? _uploadProgress; // 0..1 or null for indeterminate
  String? _uploadPhase; // 'Firebase' | 'Google Drive'

  // Google Sign-In (kept here so Drive calls can reuse silently)
  final GoogleSignIn _gsi = GoogleSignIn(
    scopes: [drive.DriveApi.driveFileScope, 'email'],
  );

  // UI strings
  String get _titleText =>
      _recordingComplete ? 'Recording complete' : _isRecording ? 'Recording' : 'Ready to Record';

  String get _clockText =>
      _formatDuration(Duration(seconds: _elapsedSeconds));

  String get _helperText {
    if (_isUploading) return 'Uploading...';
    if (_recordingComplete) return 'Choose Upload or Discard';
    if (_isRecording && _isPaused) return 'Recording paused';
    if (_isRecording) return 'Tap red to stop';
    return 'Enter class & topic, then tap the blue button to start';
  }

  bool get _isReadyToRecord =>
      !_isRecording &&
          _classCtl.text.trim().isNotEmpty &&
          _topicCtl.text.trim().isNotEmpty;

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

  String _formatDuration(Duration d) {
    final mm = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final ss = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final hh = d.inHours > 0 ? '${d.inHours}:' : '';
    return '$hh$mm:$ss';
  }

  String _fileNameFormatted({
    required String className,
    required String topic,
    required DateTime when,
  }) {
    String clean(String s) =>
        s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');
    final c = clean(className);
    final t = clean(topic);
    final y = when.year.toString().padLeft(4, '0');
    final m = when.month.toString().padLeft(2, '0');
    final d = when.day.toString().padLeft(2, '0');
    final hh = when.hour.toString().padLeft(2, '0');
    final mm = when.minute.toString().padLeft(2, '0');
    return '$c - $t - $y-$m-$d\_$hh-$mm.m4a';
  }

  Future<void> _logout() async {
    try {
      await fb.FirebaseAuth.instance.signOut();
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
        MaterialPageRoute(builder: (_) => const LoginPage()),
            (_) => false,
      );
    } catch (_) {}
  }

  // ---------------- Recording controls ----------------

  Future<void> _startRecording() async {
    final perm = await _recorder.hasPermission();
    if (!perm) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission denied')),
        );
      }
      return;
    }

    final tmp = await getTemporaryDirectory();
    final fname = _fileNameFormatted(
      className: _classCtl.text,
      topic: _topicCtl.text,
      when: DateTime.now(),
    );
    final path = '${tmp.path}/$fname';

    await WakelockPlus.enable(); // keep screen on while recording

    if (Platform.isAndroid) {
      // Use native foreground service (records when locked)
      await _recSvc.invokeMethod('startService', {'path': path});
    } else {
      // iOS/others: continue using record package
      final config = RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      );
      await _recorder.start(config, path: path);
    }

    setState(() {
      _filePath = path;
      _isRecording = true;
      _isPaused = false;
      _recordingComplete = false;
      _elapsedSeconds = 0;
    });
    _recomputeReady();

    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _isRecording && !_isPaused) {
        setState(() => _elapsedSeconds += 1);
      }
    });
  }

  Future<void> _pauseOrResume() async {
    if (!_isRecording) return;

    if (Platform.isAndroid) {
      await _recSvc.invokeMethod(_isPaused ? 'resumeService' : 'pauseService');
      setState(() => _isPaused = !_isPaused);
      return;
    }

    if (_isPaused) {
      await _recorder.resume();
    } else {
      await _recorder.pause();
    }
    setState(() => _isPaused = !_isPaused);
  }

  Future<void> _stopRecording() async {
    try {
      String? path = _filePath;
      if (Platform.isAndroid) {
        await _recSvc.invokeMethod('stopService');
        // path remains _filePath
      } else {
        path = await _recorder.stop();
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

    final createdAt = DateTime.now();
    final filename = _filePath!.split('/').last;

    // Upload to Firebase Storage first (kept as original .m4a)
    final storage = FirebaseStorage.instance;
    final pathInBucket = 'recordings/$filename';
    final ref = storage.ref().child(pathInBucket);

    final fbUploadTask = ref.putFile(
      fileOnDisk,
      SettableMetadata(contentType: 'audio/m4a'),
    );

    fbUploadTask.snapshotEvents.listen((e) {
      if (!mounted) return;
      if (e.totalBytes > 0) {
        setState(() => _uploadProgress = e.bytesTransferred / e.totalBytes);
      } else {
        setState(() => _uploadProgress = null);
      }
    });

    String storageUrl = '';
    try {
      final snap = await fbUploadTask;
      storageUrl = await snap.ref.getDownloadURL();
    } catch (e) {
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Drive upload failed: $e')),
        );
      }
    }

    // Firestore metadata (keep as before)
    final durationSeconds = _elapsedSeconds;
    await _writeFirestoreMetadata(
      filename: filename,
      className: _classCtl.text,
      topic: _topicCtl.text,
      createdAt: createdAt,
      durationSeconds: durationSeconds,
      storageUrl: storageUrl,
      driveFileId: driveId,
    );

    if (mounted) {
      setState(() {
        _isUploading = false;
        _uploadProgress = null;
        _uploadPhase = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Upload complete')),
      );
    }

    // Cleanup local file
    await _safeDeleteLocal(fileOnDisk);

    // Reset UI to fresh state
    if (mounted) {
      setState(() {
        _filePath = null;
        _recordingComplete = false;
        _elapsedSeconds = 0;
      });
    }
  }

  Future<void> _discardRecording() async {
    if (_filePath != null) {
      await _safeDeleteLocal(File(_filePath!));
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

  Future<void> _writeFirestoreMetadata({
    required String filename,
    required String className,
    required String topic,
    required DateTime createdAt,
    required int durationSeconds,
    required String storageUrl,
    required String? driveFileId,
  }) async {
    final uid = fb.FirebaseAuth.instance.currentUser?.uid;
    final meta = <String, dynamic>{
      'filename': filename,
      'className': className,
      'topic': topic,
      'createdAt': createdAt.toIso8601String(),
      'durationSeconds': durationSeconds,
      'storageUrl': storageUrl,
      'driveFileId': driveFileId,
      'uid': uid,
    };
    await FirebaseFirestore.instance.collection('recordings').add(meta);
  }

  // -------- Google Drive helpers --------
  // Wait until the file size is stable (handles MediaRecorder finishing touches)
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
      // Study Buddy / {Year}_Spring / {Class Name} / {Lecture Topic}
      final rootFolderId =
      await _getOrCreateFolder(api, 'Study Buddy', parentId: 'root');
      final yearSem = '${createdAt.year}_Spring';
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
      // Optional: set mime explicitly (Drive also infers from extension)
      if (filename.toLowerCase().endsWith('.mp3')) {
        meta.mimeType = 'audio/mpeg';
      } else if (filename.toLowerCase().endsWith('.m4a')) {
        meta.mimeType = 'audio/m4a';
      }

      // Use resumable upload — reliable for large/long recordings
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

  String _escapeForDriveQuery(String name) =>
      name.replaceAll("'", r"\'");

  // ---------------- UI ----------------
  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final big = min(w * 0.6, 300.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Buddy'),
        actions: [
          TextButton(
            onPressed: _logout,
            child: const Text('Logout',
                style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: Column(
              children: [
                const SizedBox(height: 8),
                Text(
                  _titleText,
                  style: const TextStyle(
                      fontSize: 36, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  _clockText,
                  style: const TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Text(
                  _helperText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54),
                ),
                const SizedBox(height: 18),

                // Inputs
                TextField(
                  controller: _classCtl,
                  enabled:
                  !_isRecording && !_isUploading && !_recordingComplete,
                  decoration: const InputDecoration(
                    labelText: 'Class name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _topicCtl,
                  enabled:
                  !_isRecording && !_isUploading && !_recordingComplete,
                  decoration: const InputDecoration(
                    labelText: 'Lecture topic',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 20),

                // Record / Stop
                SizedBox(
                  width: big,
                  height: big,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      shape: const CircleBorder(),
                      backgroundColor:
                      (_isRecording || _isReadyToRecord)
                          ? (_isRecording
                          ? Colors.red
                          : Colors.deepPurple)
                          : Colors.grey[400],
                    ),
                    onPressed: _isRecording
                        ? _stopRecording
                        : (_isReadyToRecord ? _startRecording : null),
                    child: Text(
                      _isRecording ? 'Stop' : 'Record',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 22),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

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
                          ? (_isPaused ? 'Resume' : 'Pause')
                          : 'Pause',
                      style: TextStyle(
                        color: _isRecording
                            ? Colors.white
                            : Colors.grey.shade600,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Upload progress
                if (_isUploading) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (_uploadProgress == null)
                        const SizedBox(
                          width: 18,
                          height: 18,
                          child:
                          CircularProgressIndicator(strokeWidth: 2),
                        ),
                      const SizedBox(width: 8),
                      Text(
                        _uploadPhase == null
                            ? 'Uploading...'
                            : 'Uploading to $_uploadPhase...',
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
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                          _isUploading ? null : _uploadRecording,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                          ),
                          child: const Text('Upload'),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed:
                          _isUploading ? null : _discardRecording,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(
                                vertical: 14),
                          ),
                          child: const Text('Discard'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

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