import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/strings.dart';
import '../utils/app_logger.dart';
import '../utils/utils.dart';

class LectureDetailScreen extends StatelessWidget {
  final String sessionId;

  const LectureDetailScreen({
    super.key,
    required this.sessionId,
  });

  String _formatSessionStatus(String status) {
    switch (status.toLowerCase()) {
      case 'ready':
        return 'Ready';
      case 'processing':
        return 'Processing';
      case 'error':
        return 'Needs attention';
      case 'unknown':
      case '':
        return 'Unknown';
      default:
        return status;
    }
  }

  String _formatAudioStatus(String status) {
    switch (status.toLowerCase()) {
      case 'uploaded':
        return 'Uploaded';
      case 'uploading':
        return 'Uploading';
      case 'error':
        return 'Upload failed';
      case 'unknown':
      case '':
        return 'Unknown';
      default:
        return status;
    }
  }

  String _formatTranscriptStatus(String status) {
    switch (status.toLowerCase()) {
      case 'done':
        return 'Transcript ready';
      case 'processing':
        return 'Processing';
      case 'pending':
        return 'Queued';
      case 'error':
        return 'Failed';
      case 'none':
      case '':
        return 'No transcript';
      default:
        return status;
    }
  }

  Future<void> _viewAiOutput(
      BuildContext context,
      String sessionId,
      String type,
      ) async {
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

      final callable = functions.httpsCallable('getAiJobOutput');
      final result = await callable.call({
        'recordingId': sessionId, // backward-compatible param name
        'sessionId': sessionId,
        'type': type,
      });

      if (!context.mounted) return;

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
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

      Map<String, dynamic> parsed;
      if (payload is Map) {
        parsed = Map<String, dynamic>.from(payload);
      } else {
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
      if (!context.mounted) return;

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
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
        final summary = data['summary'];
        final title = data['title'];
        final abstract = data['abstract'];
        final keyPoints = List<String>.from(data['key_points'] ?? const []);
        final terms = List<String>.from(data['terms'] ?? const []);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (summary != null)
              Text(summary.toString()),
            if (title != null)
              Text(
                title.toString(),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            if (abstract != null) ...[
              const SizedBox(height: 8),
              Text(abstract.toString()),
            ],
            if (keyPoints.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Text('Key Points', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              ...keyPoints.map(
                    (p) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('• $p'),
                ),
              ),
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
        final rawNotes = data['notes'] ?? data['outline'] ?? const [];
        final outline = List<Map<String, dynamic>>.from(
          (rawNotes as List).map((e) => Map<String, dynamic>.from(e as Map)),
        );
        final equations = List<String>.from(data['equations'] ?? const []);
        final refs = List<String>.from(data['references'] ?? const []);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final sec in outline) ...[
              Text(
                sec['heading']?.toString() ?? '',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              ...List<String>.from(sec['bullets'] ?? const []).map(
                    (b) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('• $b'),
                ),
              ),
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
          (data['questions'] as List? ?? const [])
              .map((e) => Map<String, dynamic>.from(e as Map)),
        );
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
                      Text(
                        (q['question'] ?? q['prompt'] ?? '').toString(),
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if ((q['choices'] as List?)?.isNotEmpty ?? false) ...[
                        const SizedBox(height: 6),
                        ...List<String>.from(q['choices'] ?? const []).map(
                              (c) => Text('○ $c'),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text('Answer: ${q['answer']?.toString() ?? ''}'),
                      if (q['explanation'] != null || q['rationale'] != null)
                        Text(
                          'Why: ${(q['explanation'] ?? q['rationale']).toString()}',
                          style: const TextStyle(color: Colors.black54),
                        ),
                    ],
                  ),
                ),
              ),
          ],
        );

      default:
        return Text(data.toString());
    }
  }

  Future<String?> _getPlaybackUrl(String storagePath) async {
    if (storagePath.trim().isEmpty) return null;
    try {
      return await FirebaseStorage.instance.ref(storagePath).getDownloadURL();
    } catch (e) {
      appLogger('Failed to get playback URL for $storagePath: $e');
      return null;
    }
  }

  Future<void> _openUrl(BuildContext context, String url) async {
    final strings = SBStrings.of(context);
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.couldNotOpenLink)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final strings = SBStrings.of(context);

    if (uid == null) {
      return Scaffold(
        appBar: AppBar(title: Text(strings.appTitle)),
        body: Center(child: Text(strings.notSignedIn)),
      );
    }

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .doc(sessionId);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: docRef.snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final doc = snap.data!;
        final m = doc.data() ?? <String, dynamic>{};

        final className = (m['className'] ?? '').toString();
        final topic = (m['topic'] ?? '').toString();
        final levelName = (m['levelName'] ?? '').toString();
        final semesterName = (m['semesterName'] ?? '').toString();

        final sessionStatus = (m['sessionStatus'] ?? 'unknown').toString();
        final audioStatus = (m['audioStatus'] ?? 'unknown').toString();
        final transcriptStatus = (m['transcriptStatus'] ?? 'none').toString();

        final summaryStatus = (m['summaryStatus'] ?? 'none').toString();
        final notesStatus = (m['notesStatus'] ?? 'none').toString();
        final quizStatus = (m['quizStatus'] ?? 'none').toString();

        final audioStoragePath = (m['audioStoragePath'] ?? '').toString();
        final filename = (m['filename'] ?? '').toString();
        final durationSeconds = (m['durationSeconds'] ?? 0) as int;

        return Scaffold(
          appBar: AppBar(title: Text('$className — $topic')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (levelName.isNotEmpty) Text('Level: $levelName'),
                      if (semesterName.isNotEmpty) Text('Semester: $semesterName'),
                      if (filename.isNotEmpty) Text('File: $filename'),
                      Text('Duration: $durationSeconds sec'),
                      Text('Session status: ${_formatSessionStatus(sessionStatus)}'),
                      Text('Audio status: ${_formatAudioStatus(audioStatus)}'),
                      Text('Transcript status: ${_formatTranscriptStatus(transcriptStatus)}'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              Text(
                strings.playback,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              if (audioStoragePath.isEmpty)
                Text(
                  strings.noPlaybackLinkAvailable,
                  style: const TextStyle(color: Colors.black54),
                )
              else
                FutureBuilder<String?>(
                  future: _getPlaybackUrl(audioStoragePath),
                  builder: (context, playbackSnap) {
                    if (playbackSnap.connectionState == ConnectionState.waiting) {
                      return const SizedBox(
                        height: 44,
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final url = playbackSnap.data;
                    if (url == null || url.isEmpty) {
                      return Text(
                        strings.noPlaybackLinkAvailable,
                        style: const TextStyle(color: Colors.black54),
                      );
                    }

                    return ElevatedButton(
                      onPressed: () => _openUrl(context, url),
                      child: Text(strings.openFromFirebaseStorage),
                    );
                  },
                ),

              const SizedBox(height: 16),
              const Divider(),

              if (transcriptStatus == 'done') ...[
                ElevatedButton(
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

                      final full = await fetchTranscript(sessionId);

                      if (!context.mounted) return;

                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }

                      if (full.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(strings.transcriptIsEmpty)),
                        );
                        return;
                      }

                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text(strings.transcript),
                          content: SizedBox(
                            width: double.maxFinite,
                            child: SingleChildScrollView(child: Text(full)),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(strings.close),
                            ),
                          ],
                        ),
                      );
                    } catch (e) {
                      if (!context.mounted) return;

                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop();
                      }
                      final msg = e.toString();
                      appLogger('Transcript UI error: $msg');
                      showDialog(
                        context: context,
                        builder: (_) => AlertDialog(
                          title: Text(strings.transcriptError),
                          content: Text(msg),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: Text(strings.ok),
                            ),
                          ],
                        ),
                      );
                    }
                  },
                  child: Text(strings.viewTranscript),
                ),
              ] else ...[
                ElevatedButton.icon(
                  icon: const Icon(Icons.text_snippet_outlined),
                  label: Text(strings.requestTranscription),
                  onPressed: () async {
                    try {
                      final firestore = FirebaseFirestore.instance;
                      final batch = firestore.batch();
                      final aiJobRef = firestore.collection('aiJobs').doc();

                      batch.update(docRef, {
                        'transcribeRequested': true,
                        'transcriptStatus': 'pending',
                        'sessionStatus': 'processing',
                        'updatedAt': FieldValue.serverTimestamp(),
                      });

                      batch.set(aiJobRef, {
                        'uid': uid,
                        'type': 'transcript',
                        'sessionId': sessionId,
                        'recordingId': sessionId, // backward-compatible
                        'status': 'pending',
                        'createdAt': FieldValue.serverTimestamp(),
                        'updatedAt': FieldValue.serverTimestamp(),
                      });

                      await batch.commit();

                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(strings.transcriptionRequested)),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Could not request transcription. Please try again.')),
                        );
                      }
                    }
                  },
                ),
              ],

              const SizedBox(height: 24),
              const Divider(),
              Text(
                strings.aiOutputs,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),

              _AiActionRow(
                title: strings.generateSummary,
                type: 'summary',
                status: summaryStatus,
                transcriptReady: transcriptStatus == 'done',
                onRequest: () async {
                  await FirebaseFirestore.instance.collection('aiJobs').add({
                    'uid': uid,
                    'type': 'summary',
                    'sessionId': sessionId,
                    'recordingId': sessionId,
                    'status': 'pending',
                    'createdAt': FieldValue.serverTimestamp(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  });

                  await docRef.update({
                    'summaryStatus': 'pending',
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                },
                sessionId: sessionId,
                viewAiOutput: _viewAiOutput,
              ),
              _AiActionRow(
                title: strings.generateNotes,
                type: 'notes',
                status: notesStatus,
                transcriptReady: transcriptStatus == 'done',
                onRequest: () async {
                  await FirebaseFirestore.instance.collection('aiJobs').add({
                    'uid': uid,
                    'type': 'notes',
                    'sessionId': sessionId,
                    'recordingId': sessionId,
                    'status': 'pending',
                    'createdAt': FieldValue.serverTimestamp(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  });

                  await docRef.update({
                    'notesStatus': 'pending',
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                },
                sessionId: sessionId,
                viewAiOutput: _viewAiOutput,
              ),
              _AiActionRow(
                title: strings.generatePracticeTest,
                type: 'quiz',
                status: quizStatus,
                transcriptReady: transcriptStatus == 'done',
                onRequest: () async {
                  await FirebaseFirestore.instance.collection('aiJobs').add({
                    'uid': uid,
                    'type': 'quiz',
                    'sessionId': sessionId,
                    'recordingId': sessionId,
                    'status': 'pending',
                    'createdAt': FieldValue.serverTimestamp(),
                    'updatedAt': FieldValue.serverTimestamp(),
                  });

                  await docRef.update({
                    'quizStatus': 'pending',
                    'updatedAt': FieldValue.serverTimestamp(),
                  });
                },
                sessionId: sessionId,
                viewAiOutput: _viewAiOutput,
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }
}

class _AiActionRow extends StatelessWidget {
  final String title;
  final String type;
  final String status;
  final Future<void> Function() onRequest;
  final bool transcriptReady;
  final String sessionId;
  final Future<void> Function(BuildContext, String, String)? viewAiOutput;

  const _AiActionRow({
    required this.title,
    required this.type,
    required this.status,
    required this.onRequest,
    required this.transcriptReady,
    required this.sessionId,
    this.viewAiOutput,
  });

  String _formatAiOutputStatus(String status) {
    switch (status.toLowerCase()) {
      case 'done':
        return 'Ready';
      case 'processing':
        return 'Processing';
      case 'pending':
        return 'Queued';
      case 'error':
        return 'Failed';
      case 'none':
      case '':
        return 'Not started';
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = SBStrings.of(context);

    return ListTile(
      leading: const Icon(Icons.auto_awesome),
      title: Text(title),
      subtitle: Text('${strings.status}: ${_formatAiOutputStatus(status)}'),
      trailing: ElevatedButton(
        onPressed: !transcriptReady
            ? null
            : (status == 'none' || status == 'error')
                ? onRequest
                : (status == 'done' && viewAiOutput != null && type.isNotEmpty)
                    ? () => viewAiOutput!(context, sessionId, type)
                    : null,
        child: Text(
          (status == 'done') ? strings.view : strings.request,
        ),
      ),
    );
  }
}