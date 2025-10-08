// lib/main.dart

// Dart
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'dart:math';

// Flutter
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

// Plugins
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

// Firebase
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:firebase_storage/firebase_storage.dart';
import 'package:path/path.dart' as path;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart'; // ✅ NEW
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';

// Google Sign-In / Drive
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:url_launcher/url_launcher.dart';

// Platform
import 'dart:io' show Platform;

// Android service channel for foreground recording
const _recSvc = MethodChannel('study_buddy/recorder_service');

// Small logger to keep output consistent
void _log(String msg) => debugPrint('[StudyBuddy] $msg');

// ✅ Single Functions handle (same app-wide region as your backend)
late FirebaseFunctions functions;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // App Check activation must be before Firebase.initializeApp.
  _log('Preparing to activate App Check...');
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider: AndroidProvider.playIntegrity,
      appleProvider: AppleProvider.appAttest,
    );
    _log('AppCheck activated with production providers');
  } catch (e) {
    _log('AppCheck activation skipped/failed: $e');
  }
  _log('App Check activation complete.');

  // ✅ Initialize Firebase directly (single call, no conditional)
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    _log('Firebase.initializeApp succeeded.');
  } catch (e) {
    _log('Firebase init failed: $e');
  }

  _log('Using Storage bucket: ${FirebaseStorage.instance.bucket}');

  // Initialize global FirebaseFunctions handle after Firebase is ready
  functions = FirebaseFunctions.instanceFor(region: 'us-central1');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Study Buddy Note',
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
        // SAFE: route to the tab shell; RecorderPage is still the first tab.
        return const HomeShell();
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
      final user = fb.FirebaseAuth.instance.currentUser;
      await _createUserIfNeeded(user);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createUserIfNeeded(fb.User? u) async {
    if (u == null) return;
    final ref = FirebaseFirestore.instance.collection('Users').doc(u.uid);
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'uid': u.uid,
        'email': u.email,
        'displayName': u.displayName,
        'photoURL': u.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'provider': 'google',
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final btnW = min(w * 0.8, 340.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Buddy Note'),
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
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),
                ],
                SizedBox(
                  width: btnW,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _signInWithGoogle,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                    ),
                    child: _loading
                        ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
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

// ----------------------------
// Bottom-Nav Shell (Additive)
// ----------------------------
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;
  final _tabs = const [
    RecorderPage(), // existing feature: record/upload flow
    LibraryScreen(), // new: browse your recordings
    SettingsScreen(), // new: placeholder for global toggles
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _tabs[_tab],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.mic), label: 'Record'),
          BottomNavigationBarItem(
              icon: Icon(Icons.library_music), label: 'Library'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
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

  // UI strings
  String get _titleText =>
      _recordingComplete ? 'Recording complete' : _isRecording ? 'Recording' : 'Ready to Record';

  String get _clockText => _formatDuration(Duration(seconds: _elapsedSeconds));

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

  // Helper to normalize file names: replace non-alphanumeric with underscores
  String _fileNameFormatted({
    required String className,
    required String topic,
    required DateTime when,
  }) {
    String clean(String s) {
      final base = s.trim().toLowerCase().replaceAll(RegExp(r'\s+'), '_');
      return base.replaceAll(RegExp(r'[^a-z0-9_-]'), '_');
    }
    final c = clean(className);
    final t = clean(topic);
    final y = when.year.toString().padLeft(4, '0');
    final m = when.month.toString().padLeft(2, '0');
    final d = when.day.toString().padLeft(2, '0');
    final hh = when.hour.toString().padLeft(2, '0');
    final mm = when.minute.toString().padLeft(2, '0');
    final ss = when.second.toString().padLeft(2, '0');
    final rand = Random().nextInt(9999).toString().padLeft(4, '0');
    return '${c}_${t}_${y}-${m}-${d}_${hh}-${mm}-${ss}_$rand.m4a';
  }
  // Helper to upload to Firebase Storage with retry on object-not-found, unauthorized, or canceled
  Future<TaskSnapshot> _uploadToStorageWithRetry(Reference ref, File file,
      {int maxRetries = 2}) async {
    int attempt = 0;
    while (true) {
      attempt++;
      try {
        return await ref.putFile(
          file,
          SettableMetadata(contentType: 'audio/mp4'),
        );
      } on FirebaseException catch (e) {
        // Retry on specific error codes
        final retryableCodes = ['object-not-found', 'unauthorized', 'canceled'];
        if (retryableCodes.contains(e.code) && attempt <= maxRetries) {
          _log('Upload retry due to "${e.code}" (attempt $attempt)...');
          await Future.delayed(const Duration(seconds: 1));
          continue;
        }
        rethrow;
      }
    }
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
    _log('Record button pressed');
    final perm = await _recorder.hasPermission();
    if (!perm) {
      _log('Microphone permission missing/denied');
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

    bool started = false;
    bool usedService = false;

    if (Platform.isAndroid && !_debugForcePluginRecorder) {
      try {
        _log('Trying to start Android foreground service...');
        final result =
        await _recSvc.invokeMethod('startService', {'path': path});
        _log('startService result: $result');
        usedService = true;
        started = await _confirmFileAppearsAndGrows(path);
        _log('Service start verified=$started');
      } catch (e) {
        _log('startService failed: $e');
        usedService = false;
        started = false;
      }
    } else if (Platform.isAndroid) {
      _log('Bypassing Android service (debug flag ON) → using plugin');
    }

    if (!started) {
      _log('Falling back to record plugin start');
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
        _log('record.start failed: $e');
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
      _log('Recording was not started (unexpected).');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recording did not start')),
        );
      }
      await WakelockPlus.disable();
      return;
    }

    _log('Recording started. mode=${usedService ? 'service' : 'plugin'} path=$path');

    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _isRecording && !_isPaused) {
        setState(() => _elapsedSeconds += 1);
      }
    });
  }

  Future<void> _pauseOrResume() async {
    if (!_isRecording) return;
    _log('Pause/Resume tapped. paused=$_isPaused');

    if (Platform.isAndroid) {
      try {
        await _recSvc.invokeMethod(_isPaused ? 'resumeService' : 'pauseService');
        setState(() => _isPaused = !_isPaused);
        _log('Service ${_isPaused ? 'paused' : 'resumed'}');
        return;
      } catch (e) {
        _log('Service pause/resume failed: $e -> falling back to plugin toggle');
      }
    }

    try {
      if (_isPaused) {
        await _recorder.resume();
      } else {
        await _recorder.pause();
      }
      setState(() => _isPaused = !_isPaused);
      _log('Plugin ${_isPaused ? 'paused' : 'resumed'}');
    } catch (e) {
      _log('Pause/resume error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Pause/Resume failed: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    _log('Stop tapped');
    try {
      String? path = _filePath;
      if (Platform.isAndroid) {
        try {
          await _recSvc.invokeMethod('stopService');
          _log('Service stopped');
        } catch (e) {
          _log('Service stop failed: $e -> trying plugin stop');
          try {
            path = await _recorder.stop();
          } catch (_) {}
        }
      } else {
        path = await _recorder.stop();
        _log('Plugin stopped, path=$path');
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
      _log('Upload requested but file missing: $_filePath');
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
    final filename = path.basename(_filePath!);

    // ✅ Ensure the file is fully finalized before ANY upload
    try {
      await _ensureFinalizedRecording(fileOnDisk);
    } catch (e) {
      _log('Recording not ready for upload: $e');
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
    final uid = fb.FirebaseAuth.instance.currentUser!.uid;
    try {
      await uploadRecording(fileOnDisk, uid);
    } catch (e) {
      _log('Firebase upload failed for path=recordings/$uid/$filename: $e');
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
      _log('Drive upload ok. fileId=$driveId');
    } catch (e) {
      _log('Drive upload failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Drive upload failed: $e')),
        );
      }
    }

    // Firestore metadata (kept as before, with additive fields)
    final durationSeconds = _elapsedSeconds;
    final fileLen = await fileOnDisk.length();
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
    _log('Firestore metadata written');

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
    _log('Local file deleted');

    // Reset UI to fresh state
    if (mounted) {
      setState(() {
        _filePath = null;
        _recordingComplete = false;
        _elapsedSeconds = 0;
      });
    }
  }

// Use the default Firebase Storage bucket from google-services.json
Future<void> uploadRecording(File file, String uid) async {
  final fileName = path.basename(file.path);
  final storagePath = "recordings/$uid/$fileName";

  _log("Uploading to Firebase Storage (default bucket) path=$storagePath");
  final storageRef = FirebaseStorage.instance
      .ref()
      .child(storagePath);


  await storageRef.putFile(
    file,
    SettableMetadata(contentType: 'audio/mp4'),
  );
}

  Future<void> _discardRecording() async {
    if (_filePath != null) {
      await _safeDeleteLocal(File(_filePath!));
      _log('Recording discarded & local file removed');
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
    _log('Finalized file length before upload: $len bytes');
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
    final uid = fb.FirebaseAuth.instance.currentUser?.uid;
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Buddy Note'),
        actions: [
          TextButton(
            onPressed: _logout,
            child: const Text('Logout', style: TextStyle(color: Colors.black)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: 16 + MediaQuery.of(context).padding.bottom,
          ),
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
                        backgroundColor: (_isRecording || _isReadyToRecord)
                            ? (_isRecording ? Colors.red : Colors.deepPurple)
                            : Colors.grey[400],
                      ),
                      onPressed: _isRecording
                          ? _stopRecording
                          : (_isReadyToRecord ? _startRecording : null),
                      child: Text(
                        _isRecording ? 'Stop' : 'Record',
                        style:
                        const TextStyle(color: Colors.white, fontSize: 22),
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
                        _isRecording ? (_isPaused ? 'Resume' : 'Pause') : 'Pause',
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
                            child: CircularProgressIndicator(strokeWidth: 2),
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
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isUploading ? null : _uploadRecording,
                            style: ElevatedButton.styleFrom(
                              padding:
                              const EdgeInsets.symmetric(vertical: 14),
                            ),
                            child: const Text('Upload'),
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
                            child: const Text('Discard'),
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
  }
}

// ---------------------------
// Library & Detail (Additive)
// ---------------------------

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});
  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  String _search = '';

  DateTime? _toDt(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final uid = fb.FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }

    final q = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('recordings');

    return Scaffold(
      appBar: AppBar(title: const Text('Library')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search classes...',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: q.snapshots(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Error loading: ${snap.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final docs = (snap.data?.docs ?? []);
                if (docs.isEmpty) {
                  return const Center(child: Text('No recordings yet.'));
                }

                // Aggregate by className
                final Map<String, _ClassRow> classes = {};
                for (final d in docs) {
                  final m = (d.data() as Map<String, dynamic>?) ?? const {};
                  final className = (m['className'] ?? '').toString().trim();
                  if (className.isEmpty) continue;

                  final createdAt = _toDt(m['createdAt']);
                  final row =
                  classes.putIfAbsent(className, () => _ClassRow(className));
                  row.count += 1;
                  if (createdAt != null &&
                      (row.latest == null || createdAt.isAfter(row.latest!))) {
                    row.latest = createdAt;
                  }
                }

                // Filter by class search
                var items = classes.values
                    .where((r) =>
                _search.isEmpty ||
                    r.className.toLowerCase().contains(_search))
                    .toList();

                // Sort by latest desc, then name
                items.sort((a, b) {
                  final la = a.latest;
                  final lb = b.latest;
                  if (la == null && lb == null) {
                    return a.className.compareTo(b.className);
                  }
                  if (la == null) return 1;
                  if (lb == null) return -1;
                  final cmp = lb.compareTo(la);
                  if (cmp != 0) return cmp;
                  return a.className.compareTo(b.className);
                });

                if (items.isEmpty) {
                  return const Center(
                      child: Text('No classes match your search.'));
                }

                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final r = items[i];
                    final subtitle = [
                      if (r.latest != null) r.latest!.toLocal().toString(),
                      '${r.count} lecture${r.count == 1 ? '' : 's'}',
                    ].join(' • ');
                    return ListTile(
                      leading: const Icon(Icons.folder),
                      title: Text(r.className,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(subtitle),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) =>
                              ClassLecturesScreen(className: r.className),
                        ));
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ClassRow {
  final String className;
  int count = 0;
  DateTime? latest;
  _ClassRow(this.className);
}

// --------------------------------------
// Class Lectures (drilldown per class)
// --------------------------------------
class ClassLecturesScreen extends StatefulWidget {
  final String className;
  const ClassLecturesScreen({super.key, required this.className});

  @override
  State<ClassLecturesScreen> createState() => _ClassLecturesScreenState();
}

class _ClassLecturesScreenState extends State<ClassLecturesScreen> {
  String _search = '';

  DateTime? _toDt(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final uid = fb.FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(body: Center(child: Text('Not signed in')));
    }

    // Filter at source: only this class + this user
    final q = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('recordings')
        .where('className', isEqualTo: widget.className);

    return Scaffold(
      appBar: AppBar(title: Text(widget.className)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search topics in this class...',
                border: OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: q.snapshots(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Error loading: ${snap.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                var docs = (snap.data?.docs ?? []).toList();

                // Filter by topic (safe reads)
                docs = docs.where((d) {
                  final m = (d.data() as Map<String, dynamic>?) ?? const {};
                  final top = (m['topic'] ?? '').toString().toLowerCase();
                  if (_search.isEmpty) return true;
                  return top.contains(_search);
                }).toList();

                // Sort newest first
                docs.sort((a, b) {
                  final ma = (a.data() as Map<String, dynamic>?) ?? const {};
                  final mb = (b.data() as Map<String, dynamic>?) ?? const {};
                  final da = _toDt(ma['createdAt']);
                  final db = _toDt(mb['createdAt']);
                  if (da == null && db == null) return 0;
                  if (da == null) return 1;
                  if (db == null) return -1;
                  return db.compareTo(da);
                });

                if (docs.isEmpty) {
                  return const Center(child: Text('No lectures yet.'));
                }

                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final d = docs[i];
                    final m = (d.data() as Map<String, dynamic>?) ?? const {};
                    final title =
                        '${(m['className'] ?? '').toString()} — ${(m['topic'] ?? '').toString()}';

                    final created = m['createdAt'];
                    final dt = created is String
                        ? DateTime.tryParse(created)
                        : (created is Timestamp ? created.toDate() : null);

                    final status = (m['transcriptStatus'] ?? 'none').toString();

                    return ListTile(
                      leading: const Icon(Icons.audiotrack),
                      title: Text(title,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        '${dt != null ? dt.toLocal().toString() : ''} • transcript: $status',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) =>
                              LectureDetailScreen(recordingId: d.id),
                        ));
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------
// Lecture Detail (safe reads + Drive playback preference)
// ---------------------------

// Enhanced: surface detailed Cloud Functions errors to the UI
Future<String> fetchTranscript(String recordingId) async {
  try {
    final callable = functions.httpsCallable('getTranscriptText');
    final result = await callable.call({'recordingId': recordingId});
    final data = result.data as Map;
    return (data['text'] as String?) ?? '';
  } on FirebaseFunctionsException catch (e) {
    _log('getTranscriptText failed: code=${e.code} message=${e.message} details=${e.details}');
    throw 'Transcript error (${e.code}): ${e.message ?? 'unknown error'}';
  } catch (e) {
    _log('getTranscriptText failed: $e');
    throw 'Transcript fetch failed: $e';
  }
}

class LectureDetailScreen extends StatelessWidget {
  final String recordingId;
  const LectureDetailScreen({super.key, required this.recordingId});

  /// Helper to fetch AI output and show dialog (formatted UI + Copy button)
  Future<void> _viewAiOutput(
      BuildContext context,
      String recordingId,
      String type,
      ) async {
    try {
      // spinner
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const AlertDialog(
          content: SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      );

      final callable = functions.httpsCallable('getAiJobOutput');
      final result = await callable.call({
        'recordingId': recordingId,
        'type': type,
      });

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(); // close spinner
      }

      final Map data = (result.data as Map?) ?? {};
      final dynamic payload = data['data'];

      if (payload == null) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('No output yet'),
            content: const Text('The AI output is empty or missing.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        return;
      }

      // Ensure we have a Map for formatting; if not, coerce via JSON roundtrip
      Map<String, dynamic> parsed;
      if (payload is Map) {
        parsed = Map<String, dynamic>.from(payload as Map);
      } else {
        // Fallback: stringify then decode
        final prettyJson = const JsonEncoder.withIndent('  ').convert(payload);
        parsed = (json.decode(prettyJson) as Map).cast<String, dynamic>();
      }

      final prettyForCopy = const JsonEncoder.withIndent('  ').convert(parsed);

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text('AI ${type[0].toUpperCase()}${type.substring(1)}'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800, maxHeight: 520),
            child: Scrollbar(
              thumbVisibility: true,
              child: SingleChildScrollView(
                child: _formatAiOutput(type, parsed),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: prettyForCopy));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Copied JSON to clipboard')),
                  );
                }
              },
              child: const Text('Copy'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(); // ensure spinner closes on error
      }
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: const Text('AI output error'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Widget _formatAiOutput(String type, Map<String, dynamic> data) {
    switch (type) {
      case 'summary':
        final title = data['title'];
        final abstract = data['abstract'];
        final keyPoints = List<String>.from(data['key_points'] ?? const []);
        final terms = List<String>.from(data['terms'] ?? const []);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null)
              Text(title.toString(),
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            if (abstract != null) ...[
              const SizedBox(height: 8),
              Text(abstract.toString()),
            ],
            if (keyPoints.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Key Points', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              ...keyPoints.map((p) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text('• $p'),
                  )),
            ],
            if (terms.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Terms', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              ...terms.map((t) => Text('- $t')),
            ],
          ],
        );

      case 'notes':
        final outline = List<Map<String, dynamic>>.from(
            (data['outline'] as List? ?? const []).map((e) => Map<String, dynamic>.from(e as Map)));
        final equations = List<String>.from(data['equations'] ?? const []);
        final refs = List<String>.from(data['references'] ?? const []);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final sec in outline) ...[
              Text(sec['heading']?.toString() ?? '',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              ...List<String>.from(sec['bullets'] ?? const [])
                  .map((b) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Text('• $b'),
                      )),
              const SizedBox(height: 10),
            ],
            if (equations.isNotEmpty) ...[
              const Text('Equations', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              ...equations.map((e) => Text(e)),
            ],
            if (refs.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('References', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              ...refs.map((r) => Text(r)),
            ],
          ],
        );

      case 'quiz':
        final questions = List<Map<String, dynamic>>.from(
            (data['questions'] as List? ?? const []).map((e) => Map<String, dynamic>.from(e as Map)));
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final q in questions)
              Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(q['prompt']?.toString() ?? '',
                          style: const TextStyle(fontWeight: FontWeight.bold)),
                      if (q['type'] == 'mcq') ...[
                        const SizedBox(height: 6),
                        ...List<String>.from(q['choices'] ?? const [])
                            .map((c) => Text('○ $c')),
                      ],
                      const SizedBox(height: 8),
                      Text('Answer: ${q['answer']?.toString() ?? ''}'),
                      if (q['rationale'] != null)
                        Text('Why: ${q['rationale']}',
                            style: const TextStyle(color: Colors.black54)),
                    ],
                  ),
                ),
              ),
          ],
        );

      default:
        // Fallback: show raw map
        return Text(data.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = fb.FirebaseAuth.instance.currentUser?.uid;
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('recordings')
        .doc(recordingId);

    return StreamBuilder<DocumentSnapshot>(
      stream: docRef.snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Scaffold(
              body: Center(child: CircularProgressIndicator()));
        }

        final doc = snap.data!;
        final m = (doc.data() as Map<String, dynamic>?) ?? const {};

        final className = (m['className'] ?? '').toString();
        final topic = (m['topic'] ?? '').toString();

        final status = (m['transcriptStatus'] ?? 'none').toString();
        final transcriptId = m['transcriptDriveFileId'];
        final subs =
            (m['subtitleDriveFileIds'] as List?)?.cast<String>() ??
                const <String>[];

        final driveFileId = (m['driveFileId'] ?? '').toString();
        final storageUrl = (m['storageUrl'] ?? '').toString();

        // Prefer Drive for playback; fall back to Storage URL for older docs
        final driveViewUrl = driveFileId.isNotEmpty
            ? 'https://drive.google.com/file/d/$driveFileId/view'
            : '';
        final playbackText = driveViewUrl.isNotEmpty
            ? 'Open in Drive:\n$driveViewUrl'
            : (storageUrl.isNotEmpty ? storageUrl : 'No playback URL available');

        return Scaffold(
          appBar: AppBar(title: Text('$className — $topic')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Playback (Drive preferred, Storage fallback) — button only
              const Text('Playback',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  Future<void> _open(String url) async {
                    final uri = Uri.parse(url);
                    if (!await launchUrl(uri,
                        mode: LaunchMode.externalApplication)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Could not open link')),
                      );
                    }
                  }

                  if (driveViewUrl.isNotEmpty) {
                    return ElevatedButton.icon(
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Open in Google Drive'),
                      onPressed: () => _open(driveViewUrl),
                    );
                  }

                  if (storageUrl.isNotEmpty) {
                    return ElevatedButton.icon(
                      icon: const Icon(Icons.link),
                      label: const Text('Open from Firebase Storage'),
                      onPressed: () => _open(storageUrl),
                    );
                  }

                  return const Text(
                    'No playback link available',
                    style: TextStyle(color: Colors.black54),
                  );
                },
              ),
              const SizedBox(height: 16),
              const Divider(),

              ListTile(
                leading: const Icon(Icons.description),
                title: const Text('Transcript status'),
                subtitle: Text(status),
              ),

              // Show “View transcript” when done (private fetch via callable)
              if (status == 'done') ...[
                const SizedBox(height: 8),
                ElevatedButton.icon(
                  icon: const Icon(Icons.text_snippet),
                  label: const Text('View transcript'),
                  onPressed: () async {
                    try {
                      showDialog(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => const AlertDialog(
                          content: SizedBox(
                            height: 80,
                            child: Center(child: CircularProgressIndicator()),
                          ),
                        ),
                      );
                      final full = await fetchTranscript(recordingId);
                      Navigator.of(context).pop(); // close progress
                      if (full.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Transcript is empty')),
                        );
                        return;
                      }
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Transcript'),
                          content: SizedBox(
                            width: double.maxFinite,
                            child: SingleChildScrollView(child: Text(full)),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Close'),
                            ),
                          ],
                        ),
                      );
                    } catch (e) {
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop(); // ensure spinner closes on error
                      }
                      final msg = e.toString();
                      _log('Transcript UI error: $msg');
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: const Text('Transcript error'),
                          content: Text(msg),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('OK'),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                ),
              ],

              const SizedBox(height: 8),
              if (status == 'none' || status == 'error')
                ElevatedButton.icon(
                  icon: const Icon(Icons.text_snippet_outlined),
                  label: const Text('Request transcription'),
                  onPressed: () async {
                    try {
                      await docRef.update({
                        'transcribeRequested': true,
                        'transcriptStatus': 'pending',
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Transcription requested.')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed: $e')),
                      );
                    }
                  },
                ),

              if (transcriptId != null)
                ListTile(
                  leading: const Icon(Icons.article),
                  title: const Text('Transcript (Google Drive)'),
                  subtitle: Text('File ID: $transcriptId'),
                ),

              for (final id in subs)
                ListTile(
                  leading: const Icon(Icons.subtitles),
                  title: const Text('Subtitles (Google Drive)'),
                  subtitle: Text('File ID: $id'),
                ),

              const SizedBox(height: 24),
              const Divider(),
              const Text('AI outputs',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              _AiActionRow(
                title: 'Generate Summary',
                status: (m['summaryStatus'] ?? 'none').toString(),
                onRequest: () async {
                  await FirebaseFirestore.instance.collection('aiJobs').add({
                    'type': 'summary',
                    'recordingId': recordingId,
                    'uid': fb.FirebaseAuth.instance.currentUser?.uid,
                    'status': 'pending',
                    'createdAt': DateTime.now().toIso8601String(),
                  });
                },
              ),
              _AiActionRow(
                title: 'Generate Notes',
                status: (m['notesStatus'] ?? 'none').toString(),
                onRequest: () async {
                  await FirebaseFirestore.instance.collection('aiJobs').add({
                    'type': 'notes',
                    'recordingId': recordingId,
                    'uid': fb.FirebaseAuth.instance.currentUser?.uid,
                    'status': 'pending',
                    'createdAt': DateTime.now().toIso8601String(),
                  });
                },
              ),
              _AiActionRow(
                title: 'Generate Practice Test',
                status: (m['quizStatus'] ?? 'none').toString(),
                onRequest: () async {
                  await FirebaseFirestore.instance.collection('aiJobs').add({
                    'type': 'quiz',
                    'recordingId': recordingId,
                    'uid': fb.FirebaseAuth.instance.currentUser?.uid,
                    'status': 'pending',
                    'createdAt': DateTime.now().toIso8601String(),
                  });
                },
              ),
              const SizedBox(height: 8),
              if ((m['summaryStatus'] ?? 'none').toString() == 'done')
                ElevatedButton.icon(
                  icon: const Icon(Icons.auto_awesome),
                  label: const Text('View Summary'),
                  onPressed: () => _viewAiOutput(context, recordingId, 'summary'),
                ),
              if ((m['notesStatus'] ?? 'none').toString() == 'done')
                ElevatedButton.icon(
                  icon: const Icon(Icons.notes),
                  label: const Text('View Notes'),
                  onPressed: () => _viewAiOutput(context, recordingId, 'notes'),
                ),
              if ((m['quizStatus'] ?? 'none').toString() == 'done')
                ElevatedButton.icon(
                  icon: const Icon(Icons.quiz),
                  label: const Text('View Practice Test'),
                  onPressed: () => _viewAiOutput(context, recordingId, 'quiz'),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _AiActionRow extends StatelessWidget {
  final String title;
  final String status;
  final Future<void> Function() onRequest;

  const _AiActionRow({
    required this.title,
    required this.status,
    required this.onRequest,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.auto_awesome),
      title: Text(title),
      subtitle: Text('Status: $status'),
      trailing: ElevatedButton(
        onPressed: (status == 'none' || status == 'error') ? onRequest : null,
        child: const Text('Request'),
      ),
    );
  }
}

// --------------------
// Settings (Additive)
// --------------------
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: const Center(
        child: Text(
            'Global toggles coming next (auto-transcribe, auto-generate, etc.)'),
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
// --------- FIREBASE STORAGE: Transcripts and Profile Images ---------

// Example: Upload transcript file to Storage under /transcripts/{uid}/
Future<String> uploadTranscriptFile(File transcriptFile, String filename) async {
  final uid = fb.FirebaseAuth.instance.currentUser!.uid;
  final ref = FirebaseStorage.instance
      .ref()
      .child('transcripts')
      .child(uid)
      .child(filename);
  final task = ref.putFile(
    transcriptFile,
    SettableMetadata(contentType: 'text/plain'),
  );
  await task;
  return await ref.getDownloadURL();
}

// Example: Upload profile image to Storage under /profile_pics/{uid}/
Future<String> uploadProfileImage(File imageFile, String filename) async {
  final uid = fb.FirebaseAuth.instance.currentUser!.uid;
  final ref = FirebaseStorage.instance
      .ref()
      .child('profile_pics')
      .child(uid)
      .child(filename);
  final task = ref.putFile(
    imageFile,
    SettableMetadata(contentType: 'image/jpeg'),
  );
  await task;
  return await ref.getDownloadURL();
}

// Upload profile image to /profile_images/{uid}/{filename} with contentType image/jpeg
Future<String> uploadProfileImageV2(File imageFile, String filename) async {
  final uid = fb.FirebaseAuth.instance.currentUser!.uid;
  final ref = FirebaseStorage.instance
      .ref()
      .child('profile_images')
      .child(uid)
      .child(filename);
  final task = ref.putFile(
    imageFile,
    SettableMetadata(contentType: 'image/jpeg'),
  );
  await task;
  return await ref.getDownloadURL();
}

// Upload user photo to /user_photos/{uid}/{filename} with contentType image/jpeg
Future<String> uploadUserPhoto(File imageFile, String filename) async {
  final uid = fb.FirebaseAuth.instance.currentUser!.uid;
  final ref = FirebaseStorage.instance
      .ref()
      .child('user_photos')
      .child(uid)
      .child(filename);
  final task = ref.putFile(
    imageFile,
    SettableMetadata(contentType: 'image/jpeg'),
  );
  await task;
  return await ref.getDownloadURL();
}