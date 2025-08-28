import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:study_buddy/firebase_options.dart';
import 'package:study_buddy/locale_provider.dart';
import 'package:study_buddy/l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(
    ChangeNotifierProvider(
      create: (context) => LocaleProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<LocaleProvider>(context);

    return MaterialApp(
      title: 'Study Buddy',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.white,
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
        ),
      ),
      locale: provider.locale,
      supportedLocales: const [
        Locale('en'),
        Locale('es'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final t = AppLocalizations.of(context)!;
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        } else if (snapshot.hasData) {
          return const RecordingScreen();
        } else {
          return Scaffold(
            appBar: AppBar(title: Text(t.appTitle)),
            body: Center(
              child: ElevatedButton(
                onPressed: () async {
                  try {
                    final GoogleSignIn googleSignIn = GoogleSignIn(
                      scopes: [
                        'email',
                        'profile',
                        'https://www.googleapis.com/auth/drive.file',
                      ],
                    );

                    await googleSignIn.signOut();

                    final GoogleSignInAccount? googleUser = await googleSignIn.signIn();

                    if (googleUser != null) {
                      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

                      final credential = GoogleAuthProvider.credential(
                        accessToken: googleAuth.accessToken,
                        idToken: googleAuth.idToken,
                      );

                      await FirebaseAuth.instance.signInWithCredential(credential);
                    }
                  } catch (e) {
                    print('Sign in error: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Sign in failed: ${e.toString()}')),
                    );
                  }
                },
                child: Text(t.signInWithGoogle),
              ),
            ),
          );
        }
      },
    );
  }
}

class RecordingScreen extends StatefulWidget {
  const RecordingScreen({super.key});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  final AudioRecorder _recorder = AudioRecorder();

  bool _isRecording = false;
  bool _isPaused = false;
  bool _isUploading = false;
  bool _isReadyToUpload = false;
  String? _currentRecordingPath;
  String _recordingDuration = "00:00";
  DateTime? _recordingStartTime;
  Duration _pausedDuration = Duration.zero;
  DateTime? _pauseStartTime;

  final _classCtrl = TextEditingController();
  final _topicCtrl = TextEditingController();

  @override
  void dispose() {
    _recorder.dispose();
    _classCtrl.dispose();
    _topicCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleRecording() async {
    if (_isRecording) {
      await _stopRecording();
    } else {
      await _startRecording();
    }
  }

  Future<void> _pauseOrResume() async {
    try {
      if (!_isRecording) return;

      if (_isPaused) {
        await _recorder.resume();
        final pausedTime = DateTime.now().difference(_pauseStartTime!);
        _pausedDuration += pausedTime;
        setState(() {
          _isPaused = false;
        });
        _startTimer();
      } else {
        await _recorder.pause();
        setState(() {
          _isPaused = true;
          _pauseStartTime = DateTime.now();
        });
      }
    } catch (e) {
      print('Pause/Resume error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pause/Resume failed: ${e.toString()}')),
      );
    }
  }

  Future<void> _startRecording() async {
    try {
      var status = await Permission.microphone.request();
      if (!status.isGranted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Microphone permission denied')),
        );
        return;
      }

      final hasPerm = await _recorder.hasPermission();
      if (!hasPerm) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recording permission not granted')),
        );
        return;
      }

      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${directory.path}/recording_$timestamp.m4a';

      await _recorder.start(
        const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 64000,
          sampleRate: 22050,
          numChannels: 1,
        ),
        path: filePath,
      );

      setState(() {
        _isRecording = true;
        _isPaused = false;
        _pausedDuration = Duration.zero;
        _currentRecordingPath = filePath;
        _recordingStartTime = DateTime.now();
        _isReadyToUpload = false;
      });

      _startTimer();
    } catch (e) {
      print('Recording start error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to start recording: ${e.toString()}')),
      );
    }
  }

  void _startTimer() {
    if (!_isRecording || _isPaused) return;

    Future.delayed(const Duration(seconds: 1), () async {
      if (_isRecording && !_isPaused && _recordingStartTime != null) {
        final duration = DateTime.now().difference(_recordingStartTime!) - _pausedDuration;
        final minutes = duration.inMinutes.toString().padLeft(2, '0');
        final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');

        if (mounted) {
          setState(() {
            _recordingDuration = "$minutes:$seconds";
          });
        }

        _startTimer();
      }
    });
  }

  Future<void> _stopRecording() async {
    try {
      final path = await _recorder.stop();
      setState(() {
        _isRecording = false;
        _isPaused = false;
        _currentRecordingPath = path;
        _isReadyToUpload = path != null;
      });
    } catch (e) {
      print('Recording stop error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to stop recording: ${e.toString()}')),
      );
    }
  }

  String _sanitizeForFilename(String input) {
    final sanitized = input
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return sanitized.isEmpty ? 'Untitled' : sanitized;
  }

  String _formatDateTime(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '${y}-${m}-${d}_${hh}-${mm}';
  }

  Future<void> _uploadRecording(File audioFile) async {
    setState(() {
      _isUploading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final now = DateTime.now();

      final className = _sanitizeForFilename(_classCtrl.text);
      final topic = _sanitizeForFilename(_topicCtrl.text);
      final stamp = _formatDateTime(now);

      final filename = '$className - $topic - $stamp.m4a';

      final storageRef = FirebaseStorage.instance
          .ref()
          .child('audio')
          .child(user.uid)
          .child(filename);

      await storageRef.putFile(audioFile);
      final downloadUrl = await storageRef.getDownloadURL();

      await FirebaseFirestore.instance.collection('lectures').add({
        'userId': user.uid,
        'title': 'Lecture ${now.day}/${now.month}/${now.year}',
        'recordedAt': now,
        'status': 'uploaded',
        'downloadUrl': downloadUrl,
      });

      await _uploadToGoogleDrive(audioFile, filename);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recording uploaded successfully!')),
        );
      }

      await audioFile.delete();
    } catch (e) {
      print('Upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
          _currentRecordingPath = null;
          _recordingDuration = "00:00";
          _isReadyToUpload = false;
        });
      }
    }
  }

  Future<void> _uploadToGoogleDrive(File audioFile, String filename) async {
    try {
      final googleSignIn = GoogleSignIn(
        scopes: ['https://www.googleapis.com/auth/drive.file'],
      );

      final account = await googleSignIn.signInSilently();
      if (account == null) return;

      final authClient = await googleSignIn.authenticatedClient();
      if (authClient == null) return;

      final driveApi = drive.DriveApi(authClient);

      final now = DateTime.now();
      final semester = '${now.year}_Spring';
      final className = _sanitizeForFilename(_classCtrl.text);
      final topicName = _sanitizeForFilename(_topicCtrl.text);

      String? studyBuddyFolderId = await _findOrCreateFolder(driveApi, 'Study Buddy', null);
      String? semesterFolderId = await _findOrCreateFolder(driveApi, semester, studyBuddyFolderId);
      String? classFolderId = await _findOrCreateFolder(driveApi, className, semesterFolderId);
      String? topicFolderId = await _findOrCreateFolder(driveApi, topicName, classFolderId);

      final driveFile = drive.File()
        ..name = filename
        ..parents = [topicFolderId!];

      await driveApi.files.create(
        driveFile,
        uploadMedia: drive.Media(audioFile.openRead(), audioFile.lengthSync()),
      );
    } catch (e) {
      print('Google Drive upload error: $e');
    }
  }

  Future<String?> _findOrCreateFolder(drive.DriveApi driveApi, String folderName, String? parentId) async {
    try {
      String query = "name='$folderName' and mimeType='application/vnd.google-apps.folder'";
      if (parentId != null) {
        query += " and '$parentId' in parents";
      }

      final searchResult = await driveApi.files.list(q: query);

      if (searchResult.files != null && searchResult.files!.isNotEmpty) {
        return searchResult.files!.first.id;
      }

      final folderMetadata = drive.File()
        ..name = folderName
        ..mimeType = 'application/vnd.google-apps.folder';

      if (parentId != null) {
        folderMetadata.parents = [parentId];
      }

      final folder = await driveApi.files.create(folderMetadata);
      return folder.id;
    } catch (e) {
      print('Folder creation error: $e');
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser!;
    final displayName = user.displayName ?? 'Student';

    final isFieldsFilled = _classCtrl.text.trim().isNotEmpty && _topicCtrl.text.trim().isNotEmpty;

    final width = MediaQuery.of(context).size.width;
    final bigBtnSize = width * 0.32;
    final bigIconSize = bigBtnSize * 0.5;
    final pauseBtnMinWidth = width * 0.46;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        title: Text('Study Buddy - $displayName'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              try {
                final GoogleSignIn googleSignIn = GoogleSignIn();
                await googleSignIn.signOut();
                await FirebaseAuth.instance.signOut();
              } catch (e) {
                print('Sign out error: $e');
              }
            },
          )
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Text(
                      _isRecording
                          ? (_isPaused ? 'Recording paused' : 'Recording...')
                          : _isReadyToUpload
                          ? 'Recording complete'
                          : 'Ready to Record',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      _recordingDuration,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontFamily: 'monospace',
                        color: _isRecording ? Colors.red : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _classCtrl,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Class name',
                        hintText: 'e.g., Math 101',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _topicCtrl,
                      textInputAction: TextInputAction.done,
                      decoration: const InputDecoration(
                        labelText: 'Lecture topic',
                        hintText: 'e.g., Calculus Derivatives',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              if (!_isReadyToUpload)
                Column(
                  children: [
                    GestureDetector(
                      onTap: (_isUploading || !isFieldsFilled) ? null : _toggleRecording,
                      child: Container(
                        width: bigBtnSize.clamp(96.0, 160.0),
                        height: bigBtnSize.clamp(96.0, 160.0),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: !isFieldsFilled
                              ? Colors.grey
                              : (_isRecording ? Colors.red : Colors.blue),
                          boxShadow: [
                            BoxShadow(
                              color: (!isFieldsFilled
                                  ? Colors.grey
                                  : (_isRecording ? Colors.red : Colors.blue))
                                  .withOpacity(0.3),
                              spreadRadius: 5,
                              blurRadius: 15,
                            ),
                          ],
                        ),
                        child: Icon(
                          _isRecording ? Icons.stop : Icons.mic,
                          color: Colors.white,
                          size: bigIconSize.clamp(44.0, 88.0),
                        ),
                      ),
                    ),
                    if (_isRecording) ...[
                      const SizedBox(height: 12),
                      ConstrainedBox(
                        constraints: BoxConstraints(minWidth: pauseBtnMinWidth),
                        child: ElevatedButton.icon(
                          onPressed: _pauseOrResume,
                          icon: Icon(_isPaused ? Icons.play_arrow : Icons.pause),
                          label: Text(_isPaused ? "Resume" : "Pause"),
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(0, 44),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              if (_isReadyToUpload && !_isUploading) ...[
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        if (_currentRecordingPath != null) {
                          _uploadRecording(File(_currentRecordingPath!));
                        }
                      },
                      icon: const Icon(Icons.cloud_upload),
                      label: const Text("Upload"),
                    ),
                    const SizedBox(width: 20),
                    ElevatedButton.icon(
                      onPressed: () async {
                        if (_currentRecordingPath != null) {
                          try {
                            await File(_currentRecordingPath!).delete();
                          } catch (_) {}
                        }
                        setState(() {
                          _currentRecordingPath = null;
                          _isReadyToUpload = false;
                          _recordingDuration = "00:00";
                        });
                      },
                      icon: const Icon(Icons.delete),
                      label: const Text("Discard"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 24),
              if (_isUploading)
                const Column(
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 10),
                    Text('Uploading recording...'),
                  ],
                ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  _isRecording
                      ? (_isPaused
                      ? 'Recording is paused'
                      : 'Tap the red button to stop recording')
                      : _isReadyToUpload
                      ? 'Choose to upload or discard this recording'
                      : 'Tap the blue button to start recording your lecture',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}