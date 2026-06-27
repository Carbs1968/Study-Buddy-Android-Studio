import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../firebase_options.dart';
import '../../../l10n/strings.dart';
import '../../../utils/app_logger.dart';
import '../../../utils/helper.dart';

// Android service channel for foreground recording
const _recSvc = MethodChannel('study_buddy/recorder_service');

enum _RecordingBackend { none, nativeService, plugin }

class RecorderPage extends StatefulWidget {
  const RecorderPage({super.key});

  @override
  State<RecorderPage> createState() => _RecorderPageState();
}

class _RecorderPageState extends State<RecorderPage> with WidgetsBindingObserver {
  final FocusNode _topicFocus = FocusNode();

  bool _selectedExistingClass = false;

  final TextEditingController _classCtl = TextEditingController();
  final TextEditingController _topicCtl = TextEditingController();

  final AudioRecorder _recorder = AudioRecorder();

  Timer? _ticker;
  String? _filePath;
  bool _isRecording = false;
  bool _isPaused = false;
  bool _recordingComplete = false;
  bool _checkingRecordingHealth = false;
  int _elapsedSeconds = 0;
  _RecordingBackend _recordingBackend = _RecordingBackend.none;

  static const bool _debugForcePluginRecorder = false;
  static const int _nativeFileStaleWarningMillis = 20000;

  bool _isUploading = false;
  double? _uploadProgress;
  String? _uploadPhase;

  late Future<List<String>> _classNamesFuture;

  bool _isLoadingAcademicSettings = true;
  String? _levelName;
  String? _semesterName;

  String get _titleText {
    final strings = SBStrings.of(context);
    if (_recordingComplete) return strings.recordingComplete;
    if (_isRecording) return strings.recording;
    return strings.readyToRecord;
  }

  String get _clockText => formatDuration(Duration(seconds: _elapsedSeconds));

  String get _helperText {
    final strings = SBStrings.of(context);
    if (_isLoadingAcademicSettings) return 'Loading...';
    if (_isUploading) return strings.uploading;
    if (_recordingComplete) return strings.chooseUploadOrDiscard;
    if (_isRecording && _isPaused) {
      return 'Recording paused. Tap Resume to continue. Your recording is still saved.';
    }
    if (_isRecording) {
      return 'Recording continues if your screen locks.';
    }
    return '';
  }

  bool get _isReadyToRecord =>
      !_isLoadingAcademicSettings &&
          !_isRecording &&
          (_levelName?.trim().isNotEmpty ?? false) &&
          (_semesterName?.trim().isNotEmpty ?? false) &&
          _classCtl.text.trim().isNotEmpty &&
          _topicCtl.text.trim().isNotEmpty;

  @override
  void initState() {
    super.initState();
    _classNamesFuture = _fetchClassNames();
    WidgetsBinding.instance.addObserver(this);
    _classCtl.addListener(_recomputeReady);
    _topicCtl.addListener(_recomputeReady);
    _loadAcademicSettings();
    unawaited(_restoreRecoverableRecordingState());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    _topicFocus.dispose();
    _classCtl.dispose();
    _topicCtl.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (_isRecording) {
        unawaited(_verifyActiveRecordingHealth());
      } else {
        unawaited(_restoreRecoverableRecordingState());
      }
    }
  }

  void _recomputeReady() {
    if (mounted) setState(() {});
  }

  Future<void> _loadAcademicSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) {
        setState(() => _isLoadingAcademicSettings = false);
      }
      return;
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('academicSettings')
          .doc('current')
          .get();

      final data = doc.data();
      if (mounted) {
        setState(() {
          _levelName = (data?['levelName'] ?? '').toString().trim();
          _semesterName = (data?['semesterName'] ?? '').toString().trim();
          _isLoadingAcademicSettings = false;
        });
      }
    } catch (e) {
      appLogger('Failed to load academic settings: $e');
      if (mounted) {
        setState(() => _isLoadingAcademicSettings = false);
      }
    }
  }

  Future<bool> _ensureAcademicSettingsReady() async {
    if ((_levelName?.trim().isNotEmpty ?? false) &&
        (_semesterName?.trim().isNotEmpty ?? false)) {
      return true;
    }

    await _loadAcademicSettings();

    final ok = (_levelName?.trim().isNotEmpty ?? false) &&
        (_semesterName?.trim().isNotEmpty ?? false);

    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please save your academic level and semester first in Academic Settings.',
          ),
        ),
      );
    }

    return ok;
  }

  Future<List<String>> _fetchClassNames() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .get();

    final classes = snap.docs
        .map((d) => (d.data()['className'] ?? '').toString().trim())
        .where((s) => s.isNotEmpty)
        .toSet()
        .toList()
      ..sort();

    return classes;
  }

  Future<bool> _confirmFileAppearsAndGrows(
      String path, {
        Duration timeout = const Duration(seconds: 3),
      }) async {
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

  void _startTicker() {
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted && _isRecording && !_isPaused) {
        setState(() => _elapsedSeconds += 1);
        if (_elapsedSeconds % 5 == 0) {
          unawaited(_verifyActiveRecordingHealth());
        }
      }
    });
  }

  Future<Directory> _pendingRecordingsDirectory() async {
    final docs = await getApplicationDocumentsDirectory();
    return Directory(path.join(docs.path, 'pending_recordings'));
  }

  Future<void> _restoreRecoverableRecordingState() async {
    if (_isRecording || _recordingComplete || _isUploading) return;

    final restoredNative = await _restoreNativeRecordingState();
    if (!restoredNative) {
      await _restoreLatestPendingRecording();
    }
  }

  Future<bool> _restoreNativeRecordingState() async {
    if (!Platform.isAndroid || _debugForcePluginRecorder) return false;

    try {
      final raw = await _recSvc.invokeMapMethod<String, dynamic>('getServiceState');
      if (raw == null) return false;

      final isRecording = raw['isRecording'] == true;
      final restoredPath = raw['path']?.toString();
      if (!isRecording || restoredPath == null || restoredPath.isEmpty) {
        return false;
      }

      if (!_isHealthyNativeRecordingState(raw)) {
        appLogger('Native recording state looks stale/unhealthy: $raw');
        final recovered = await _recoverPartialNativeRecording(
          restoredPath,
          'Recording appears to have stopped. Recovered audio may be partial.',
        );
        return recovered;
      }

      final elapsedMillis = raw['elapsedMillis'];
      final restoredElapsedSeconds =
          elapsedMillis is num ? (elapsedMillis / 1000).floor() : _elapsedSeconds;

      if (!mounted) return false;
      setState(() {
        _filePath = restoredPath;
        _isRecording = true;
        _isPaused = raw['isPaused'] == true;
        _recordingComplete = false;
        _elapsedSeconds = restoredElapsedSeconds;
        _recordingBackend = _RecordingBackend.nativeService;
      });
      await WakelockPlus.enable();
      _startTicker();
      appLogger('Restored native recording state: path=$restoredPath');
      return true;
    } catch (e) {
      appLogger('Native recording state restore skipped: $e');
      return false;
    }
  }

  Future<void> _restoreLatestPendingRecording() async {
    try {
      final recordingsDir = await _pendingRecordingsDirectory();
      if (!await recordingsDir.exists()) return;

      final candidates = <File>[];
      await for (final entity in recordingsDir.list(followLinks: false)) {
        if (entity is File &&
            path.extension(entity.path).toLowerCase() == '.m4a' &&
            await entity.exists() &&
            await entity.length() > 0) {
          candidates.add(entity);
        }
      }

      if (candidates.isEmpty) return;

      candidates.sort((a, b) {
        return b.lastModifiedSync().compareTo(a.lastModifiedSync());
      });

      final latest = candidates.first;
      await _restorePendingRecordingFile(latest);
    } catch (e) {
      appLogger('Pending recording restore skipped: $e');
    }
  }

  bool _isHealthyNativeRecordingState(Map<String, dynamic> raw) {
    if (raw['isRecording'] != true) return false;
    if (raw['recorderPresent'] != true || raw['hasStarted'] != true) return false;
    if (raw['fileExists'] != true) return false;

    final isPaused = raw['isPaused'] == true;
    final size = raw['fileSizeBytes'];
    if (!isPaused && (size is! num || size <= 0)) return false;

    final staleMillis = raw['fileStaleMillis'];
    if (!isPaused &&
        staleMillis is num &&
        staleMillis > _nativeFileStaleWarningMillis) {
      return false;
    }

    return true;
  }

  Future<bool> _recoverPartialNativeRecording(
    String filePath,
    String warning,
  ) async {
    try {
      await _recSvc.invokeMethod('stopService');
    } catch (e) {
      appLogger('Failed to stop stale native service during recovery: $e');
    }

    final file = File(filePath);
    if (!await file.exists() || await file.length() <= 0) {
      return false;
    }

    await _restorePendingRecordingFile(
      file,
      warning: warning,
      replaceActive: true,
    );
    return true;
  }

  Future<void> _restorePendingRecordingFile(
    File file, {
    String? warning,
    bool replaceActive = false,
  }) async {
    _restoreClassAndTopicFromFilename(file.path);

    final durationSeconds = await _readAudioDurationSeconds(file.path);
    if (!mounted ||
        (_isRecording && !replaceActive) ||
        _recordingComplete ||
        _isUploading) {
      return;
    }
    setState(() {
      _filePath = file.path;
      _isRecording = false;
      _isPaused = false;
      _recordingComplete = true;
      _elapsedSeconds = durationSeconds ?? 0;
      _recordingBackend = _RecordingBackend.none;
    });

    final len = await file.length();
    appLogger('Restored pending recording for upload/discard: ${file.path}');
    if (mounted && (warning != null || len < 4096)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            warning ??
                'Recovered a pending recording, but it looks very small ($len bytes). You can try uploading it or discard it.',
          ),
        ),
      );
    }
  }

  Future<void> _verifyActiveRecordingHealth() async {
    if (_checkingRecordingHealth ||
        !_isRecording ||
        _isPaused ||
        _recordingBackend != _RecordingBackend.nativeService ||
        !Platform.isAndroid ||
        _debugForcePluginRecorder) {
      return;
    }

    _checkingRecordingHealth = true;
    try {
      final raw = await _recSvc.invokeMapMethod<String, dynamic>('getServiceState');
      if (raw == null || _isHealthyNativeRecordingState(raw)) return;

      final recoveredPath = raw['path']?.toString() ?? _filePath;
      appLogger('Active native recording failed health check: $raw');
      _ticker?.cancel();

      if (recoveredPath != null && recoveredPath.isNotEmpty) {
        final recovered = await _recoverPartialNativeRecording(
          recoveredPath,
          'Recording appears to have stopped. Recovered audio may be partial.',
        );
        if (recovered) {
          await WakelockPlus.disable();
          return;
        }
      }

      if (!mounted) return;
      setState(() {
        _isRecording = false;
        _isPaused = false;
        _recordingBackend = _RecordingBackend.none;
      });
      await WakelockPlus.disable();
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Recording appears to have stopped, but no recoverable audio file was found.',
          ),
        ),
      );
    } catch (e) {
      appLogger('Active recording health check skipped: $e');
    } finally {
      _checkingRecordingHealth = false;
    }
  }

  Future<int?> _readAudioDurationSeconds(String filePath) async {
    if (!Platform.isAndroid) return null;

    try {
      final raw = await _recSvc.invokeMethod<dynamic>(
        'getAudioDurationMillis',
        {'path': filePath},
      );
      if (raw is! num || raw <= 0) return null;
      return (raw / 1000).ceil();
    } catch (e) {
      appLogger('Could not read audio duration for $filePath: $e');
      return null;
    }
  }

  Map<String, String>? _classAndTopicFromFilename(String filePath) {
    final fileName = path.basename(filePath);
    final match = RegExp(
      r'^(.+) - (.+) - \d{4}-\d{2}-\d{2}_\d{2}-\d{2}\.m4a$',
    ).firstMatch(fileName);
    if (match == null) return null;

    final className = match.group(1)?.trim() ?? '';
    final topic = match.group(2)?.trim() ?? '';
    if (className.isEmpty || topic.isEmpty) return null;

    return {
      'className': className,
      'topic': topic,
    };
  }

  void _restoreClassAndTopicFromFilename(String filePath) {
    final parsed = _classAndTopicFromFilename(filePath);
    if (parsed == null) return;

    _classCtl.text = parsed['className']!;
    _topicCtl.text = parsed['topic']!;
    _selectedExistingClass = false;
  }

  Map<String, String>? _resolveUploadMetadata(String filePath) {
    var resolvedClassName = _classCtl.text.trim();
    var resolvedTopic = _topicCtl.text.trim();
    final parsed = _classAndTopicFromFilename(filePath);

    if (parsed != null) {
      if (resolvedClassName.isEmpty) {
        resolvedClassName = parsed['className']!;
      }
      if (resolvedTopic.isEmpty) {
        resolvedTopic = parsed['topic']!;
      }
    }

    if (resolvedClassName.isEmpty || resolvedTopic.isEmpty) return null;

    final resolvedClassId = _stableDocumentId(resolvedClassName);
    if (resolvedClassId == 'unnamed') return null;

    if (_classCtl.text.trim() != resolvedClassName) {
      _classCtl.text = resolvedClassName;
      _selectedExistingClass = false;
    }
    if (_topicCtl.text.trim() != resolvedTopic) {
      _topicCtl.text = resolvedTopic;
      _selectedExistingClass = false;
    }

    final resolvedTopicKey = _stableDocumentId(resolvedTopic);

    return {
      'className': resolvedClassName,
      'topic': resolvedTopic,
      'topicName': resolvedTopic,
      'topicKey': resolvedTopicKey,
      'classId': resolvedClassId,
    };
  }

  Future<void> _startRecording() async {
    appLogger('Record button pressed');

    final academicReady = await _ensureAcademicSettingsReady();
    if (!academicReady) return;

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

    final recordingsDir = await _pendingRecordingsDirectory();
    await recordingsDir.create(recursive: true);

    final fname = fileNameFormatted(
      className: _classCtl.text,
      topic: _topicCtl.text,
      when: DateTime.now(),
    );
    final filePath = path.join(recordingsDir.path, fname);

    await WakelockPlus.enable();

    bool started = false;
    bool usedService = false;
    _recordingBackend = _RecordingBackend.none;

    if (Platform.isAndroid && !_debugForcePluginRecorder) {
      try {
        appLogger('Trying to start Android foreground service...');
        final result =
        await _recSvc.invokeMethod('startService', {'path': filePath});
        appLogger('startService result: $result');
        usedService = true;
        started = await _confirmFileAppearsAndGrows(filePath);
        if (started) {
          _recordingBackend = _RecordingBackend.nativeService;
        }
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
          numChannels: 1,
        );
        await _recorder.start(config, path: filePath);
        started = true;
        usedService = false;
        _recordingBackend = _RecordingBackend.plugin;
      } catch (e) {
        appLogger('record.start failed: $e');
        _recordingBackend = _RecordingBackend.none;
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
      _filePath = filePath;
      _isRecording = started;
      _isPaused = false;
      _recordingComplete = false;
      _elapsedSeconds = 0;
    });
    _recomputeReady();

    if (!started) {
      appLogger('Recording was not started (unexpected).');
      _recordingBackend = _RecordingBackend.none;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Recording did not start')),
        );
      }
      await WakelockPlus.disable();
      return;
    }

    appLogger(
      'Recording started. mode=${usedService ? 'service' : 'plugin'} path=$filePath',
    );

    _startTicker();
  }

  Future<void> _pauseOrResume() async {
    if (!_isRecording) return;
    appLogger('Pause/Resume tapped. paused=$_isPaused');

    switch (_recordingBackend) {
      case _RecordingBackend.nativeService:
        try {
          await _recSvc.invokeMethod(_isPaused ? 'resumeService' : 'pauseService');
          setState(() => _isPaused = !_isPaused);
          appLogger('Service ${_isPaused ? 'paused' : 'resumed'}');
        } catch (e) {
          appLogger('Service pause/resume failed: $e');
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Pause/Resume failed: $e')),
            );
          }
        }
        return;
      case _RecordingBackend.plugin:
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
        return;
      case _RecordingBackend.none:
        appLogger('Pause/resume blocked: recording backend is unknown.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Cannot pause/resume: recording backend is unknown.'),
            ),
          );
        }
        return;
    }
  }

  Future<void> _stopRecording() async {
    appLogger('Stop tapped');
    try {
      String? finalPath = _filePath;
      var stopped = false;

      switch (_recordingBackend) {
        case _RecordingBackend.nativeService:
          await _recSvc.invokeMethod('stopService');
          appLogger('Service stopped');
          stopped = true;
          break;
        case _RecordingBackend.plugin:
          finalPath = await _recorder.stop();
          appLogger('Plugin stopped, path=$finalPath');
          stopped = true;
          break;
        case _RecordingBackend.none:
          appLogger('Stop requested with unknown recording backend.');
          if (Platform.isAndroid && !_debugForcePluginRecorder) {
            try {
              final raw =
                  await _recSvc.invokeMapMethod<String, dynamic>('getServiceState');
              if (raw != null && raw['isRecording'] == true) {
                _recordingBackend = _RecordingBackend.nativeService;
                await _recSvc.invokeMethod('stopService');
                appLogger('Service stopped after unknown-backend recovery');
                stopped = true;
                final nativePath = raw['path']?.toString();
                if (nativePath != null && nativePath.isNotEmpty) {
                  finalPath = nativePath;
                }
                break;
              }
            } catch (e) {
              appLogger('Unknown-backend native stop recovery failed: $e');
            }
          }

          try {
            final pluginPath = await _recorder.stop();
            if (pluginPath != null && pluginPath.isNotEmpty) {
              finalPath = pluginPath;
            }
            stopped = true;
            appLogger('Plugin stopped after unknown-backend recovery');
          } catch (e) {
            appLogger('Unknown-backend plugin stop recovery failed: $e');
          }
          break;
      }

      final usablePath = finalPath ?? _filePath;
      if (!stopped || usablePath == null || usablePath.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Could not confirm recording stopped. Please try again before leaving this screen.',
              ),
            ),
          );
        }
        return;
      }

      _ticker?.cancel();
      setState(() {
        _isRecording = false;
        _isPaused = false;
        _recordingComplete = true;
        _filePath = usablePath;
        _recordingBackend = _RecordingBackend.none;
      });
    } finally {
      await WakelockPlus.disable();
      _recomputeReady();
    }
  }


  String _stableDocumentId(String value) {
    final normalized = value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[áàäâã]'), 'a')
        .replaceAll(RegExp(r'[éèëê]'), 'e')
        .replaceAll(RegExp(r'[íìïî]'), 'i')
        .replaceAll(RegExp(r'[óòöôõ]'), 'o')
        .replaceAll(RegExp(r'[úùüû]'), 'u')
        .replaceAll('ñ', 'n')
        .replaceAll('ç', 'c');

    final slug = normalized
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');

    return slug.isEmpty ? 'unnamed' : slug;
  }

  Future<void> _uploadRecording() async {
    if (_filePath == null) return;

    final academicReady = await _ensureAcademicSettingsReady();
    if (!academicReady) return;

    final fileOnDisk = File(_filePath!);
    if (!await fileOnDisk.exists()) {
      appLogger('Upload requested but file missing: $_filePath');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('File missing')),
        );
      }
      return;
    }

    setState(() {
      _isUploading = true;
      _uploadProgress = 0;
      _uploadPhase = 'Firebase';
    });

    Reference? uploadedStorageRef;
    var sessionVerified = false;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No authenticated user');
      }

      final uid = user.uid;
      final filename = path.basename(_filePath!);
      final storagePath = 'recordings/$uid/$filename';
      final academicYearName = _levelName!.trim();
      final semesterName = _semesterName!.trim();
      final academicYearId = _stableDocumentId(academicYearName);
      final semesterId = _stableDocumentId(semesterName);

      await _ensureFinalizedRecording(fileOnDisk);
      final uploadMetadata = _resolveUploadMetadata(fileOnDisk.path);
      if (uploadMetadata == null) {
        appLogger('Upload blocked: missing class/topic metadata for $_filePath');
        if (mounted) {
          setState(() {
            _isUploading = false;
            _uploadProgress = null;
            _uploadPhase = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please enter a class and topic before uploading.'),
            ),
          );
        }
        return;
      }

      final className = uploadMetadata['className']!;
      final topic = uploadMetadata['topic']!;
      final classId = uploadMetadata['classId']!;
      appLogger(
        'Saving session metadata: '
        'filename=$filename '
        'resolvedClassName=$className '
        'resolvedTopic=$topic '
        'resolvedClassId=$classId',
      );
      final actualDurationSeconds =
          await _readAudioDurationSeconds(fileOnDisk.path);
      final durationSeconds = actualDurationSeconds ?? _elapsedSeconds;
      if (actualDurationSeconds == null) {
        appLogger(
          'Audio duration unavailable; falling back to UI elapsed seconds=$_elapsedSeconds',
        );
      } else {
        appLogger('Audio duration from media metadata: $durationSeconds seconds');
      }

      final userRef = FirebaseFirestore.instance.collection('users').doc(uid);
      final academicYearRef = userRef
          .collection('academicYears')
          .doc(academicYearId);
      final semesterRef = academicYearRef
          .collection('semesters')
          .doc(semesterId);
      final classRef = semesterRef
          .collection('classes')
          .doc(classId);
      final sessionRef = userRef.collection('sessions').doc();

      await academicYearRef.set({
        'userId': uid,
        'academicYearId': academicYearId,
        'academicYearName': academicYearName,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await semesterRef.set({
        'userId': uid,
        'academicYearId': academicYearId,
        'semesterId': semesterId,
        'semesterName': semesterName,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      await classRef.set({
        'userId': uid,
        'academicYearId': academicYearId,
        'academicYearName': academicYearName,
        'semesterId': semesterId,
        'semesterName': semesterName,
        'classId': classId,
        'className': className,
        'createdAt': FieldValue.serverTimestamp(),
        'lastActivityAt': FieldValue.serverTimestamp(),
        'lastRecordingAt': FieldValue.serverTimestamp(),
        'latestSessionId': sessionRef.id,
        'latestTopicName': topic,
        'hasRecordings': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final storageRef = FirebaseStorage.instance.ref().child(storagePath);
      uploadedStorageRef = storageRef;
      final uploadTask = storageRef.putFile(
        fileOnDisk,
        SettableMetadata(contentType: 'audio/mp4'),
      );

      StreamSubscription<TaskSnapshot>? progressSub;
      progressSub = uploadTask.snapshotEvents.listen((snapshot) {
        if (!mounted) return;
        final total = snapshot.totalBytes;
        final transferred = snapshot.bytesTransferred;
        final progress = total > 0 ? transferred / total : null;

        setState(() {
          _uploadProgress = progress;
          _uploadPhase = 'Firebase';
        });
      });

      await uploadTask;
      await progressSub.cancel();

      final fileLen = await fileOnDisk.length();
      final storageMetadata = await storageRef.getMetadata();
      if (storageMetadata.size == null || storageMetadata.size == 0) {
        throw Exception('Storage upload verification failed: empty object');
      }

      if (mounted) {
        setState(() {
          _uploadPhase = 'Firestore';
        });
      }

      await sessionRef.set({
        'userId': uid,
        'academicYearId': academicYearId,
        'academicYearName': academicYearName,
        'levelName': academicYearName,
        'semesterId': semesterId,
        'semesterName': semesterName,
        'classId': classId,
        'className': className,
        'topic': topic,
        'topicName': topic,
        'topicKey': _stableDocumentId(topic),
        'filename': filename,
        'audioStoragePath': storagePath,
        'audioMimeType': 'audio/mp4',
        'sizeBytes': fileLen,
        'durationSeconds': durationSeconds,
        'sessionStatus': 'uploaded',
        'audioStatus': 'uploaded',
        'transcriptStatus': 'none',
        'summaryStatus': 'none',
        'notesStatus': 'none',
        'quizStatus': 'none',
        'flashcardsStatus': 'none',
        'studyGuideStatus': 'none',
        'embeddingStatus': 'none',
        'transcribeRequested': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final saved = await sessionRef.get();
      if (!saved.exists) {
        throw Exception('Session metadata verification failed: doc missing');
      }
      final savedData = saved.data() ?? <String, dynamic>{};
      if (savedData['classId'] != classId ||
          savedData['className'] != className ||
          savedData['topic'] != topic) {
        throw Exception('Session metadata verification failed');
      }
      sessionVerified = true;
      appLogger(
        'Verified saved session metadata: '
        'classId=${savedData['classId']} '
        'className=${savedData['className']} '
        'topic=${savedData['topic']}',
      );

      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = null;
          _uploadPhase = null;
        });

        _classCtl.clear();
        _topicCtl.clear();
        _selectedExistingClass = false;

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upload complete. Ready for your next lecture!'),
          ),
        );
      }

      await _safeDeleteLocal(fileOnDisk);
      appLogger('Local file deleted');

      if (mounted) {
        setState(() {
          _filePath = null;
          _recordingComplete = false;
          _elapsedSeconds = 0;
          _recordingBackend = _RecordingBackend.none;
        });
      }
    } catch (e) {
      appLogger('Upload failed: $e');
      if (!sessionVerified && uploadedStorageRef != null) {
        try {
          await uploadedStorageRef.delete();
          appLogger('Deleted orphaned Storage upload after Firestore failure');
        } catch (cleanupError) {
          appLogger('Could not delete orphaned Storage upload: $cleanupError');
        }
      }
      if (mounted) {
        setState(() {
          _isUploading = false;
          _uploadProgress = null;
          _uploadPhase = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
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
        _recordingBackend = _RecordingBackend.none;
      });
    }
  }

  Future<void> _safeDeleteLocal(File f) async {
    try {
      if (await f.exists()) {
        await f.delete();
      }
    } catch (_) {}
  }

  Future<void> _ensureFinalizedRecording(File f) async {
    final len = await _waitForStableFileLength(f);
    appLogger('Finalized file length before upload: $len bytes');
    if (len < 4096) {
      throw 'Recording looks empty or corrupt (size $len bytes). Please record again.';
    }
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

  Widget _buildAcademicInfoCard(BuildContext context) {
      final hasSettings =
          (_levelName?.trim().isNotEmpty ?? false) &&
              (_semesterName?.trim().isNotEmpty ?? false);

      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;

      final bgColor = hasSettings
          ? (isDark ? const Color(0xFF1E1A2E) : const Color(0xFFF2ECFF))
          : (isDark ? const Color(0xFF3A2416) : const Color(0xFFFFF4E5));

      final borderColor = hasSettings
          ? (isDark ? const Color(0xFF6E56CF) : const Color(0xFFD5C7FF))
          : (isDark ? const Color(0xFFFFB366) : const Color(0xFFFFD8A8));

      final titleColor = theme.textTheme.titleMedium?.color ?? Colors.white;
      final textColor = theme.textTheme.bodyMedium?.color ?? Colors.white70;

      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor, width: 1.2),
        ),
        child: _isLoadingAcademicSettings
            ? Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Loading academic settings...',
                style: TextStyle(color: textColor),
              ),
            ),
          ],
        )
            : hasSettings
            ? Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current academic defaults',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 16,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Level: ${_levelName!}',
              style: TextStyle(
                color: textColor,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Semester: ${_semesterName!}',
              style: TextStyle(
                color: textColor,
                fontSize: 15,
              ),
            ),
          ],
        )
            : Text(
          'Please save your academic level and semester in Academic Settings before recording.',
          style: TextStyle(
            color: textColor,
            fontSize: 15,
          ),
        ),
      );
    }

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
            onRefresh: () async {
              await _loadAcademicSettings();
              setState(() {
                _classNamesFuture = _fetchClassNames();
              });
              await _classNamesFuture;
            },
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 16,
                bottom: 16 + MediaQuery.of(context).padding.bottom,
              ),
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
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
                              style: TextStyle(
                                fontSize: 22,
                                color: Theme.of(context).textTheme.titleLarge?.color,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_helperText.isNotEmpty) ...[
                          Text(
                            _helperText,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        _buildAcademicInfoCard(context),
                        const SizedBox(height: 12),

                        FutureBuilder<List<String>>(
                          future: _classNamesFuture,
                          builder: (context, snapshot) {
                            final classList = snapshot.data ?? [];
                            final dropdownValue = classList.contains(_classCtl.text)
                                ? _classCtl.text
                                : null;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting)
                                  const LinearProgressIndicator(minHeight: 2),
                                DropdownButtonFormField<String>(
                                  initialValue: dropdownValue,
                                  decoration: InputDecoration(
                                    labelText: strings.selectClass,
                                    border: const OutlineInputBorder(),
                                  ),
                                  items: classList
                                      .map(
                                        (name) => DropdownMenuItem(
                                      value: name,
                                      child: Text(name),
                                    ),
                                  )
                                      .toList(),
                                  onChanged: (val) {
                                    setState(() {
                                      if (val != null) {
                                        _selectedExistingClass = true;
                                        _classCtl.text = val;
                                        FocusScope.of(context)
                                            .requestFocus(_topicFocus);
                                      } else {
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
                                    enabled: !_isRecording &&
                                        !_isUploading &&
                                        !_recordingComplete,
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
                          enabled:
                          !_isRecording && !_isUploading && !_recordingComplete,
                          decoration: InputDecoration(
                            labelText: strings.lectureTopic,
                            border: const OutlineInputBorder(),
                          ),
                        ),

                        const SizedBox(height: 14),

                        SizedBox(
                          width: big,
                          height: big,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              shape: const CircleBorder(),
                              backgroundColor: (_isRecording || _isReadyToRecord)
                                  ? (_isRecording
                                  ? Colors.red
                                  : Colors.deepPurple.shade600)
                                  : Colors.grey[400],
                            ),
                            onPressed: _isRecording
                                ? _stopRecording
                                : (_isReadyToRecord ? _startRecording : null),
                            child: Text(
                              _isRecording ? strings.stop : strings.record,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12),

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

                        if (_isUploading) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_uploadProgress == null)
                                const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
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
                              value: _uploadProgress,
                              minHeight: 6,
                            ),
                        ],

                        if (_recordingComplete) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: _isUploading ? null : _uploadRecording,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepPurple.shade600,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
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
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 14,
                                    ),
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
