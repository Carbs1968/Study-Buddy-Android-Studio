import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';
import 'ai_output_screen.dart';
import '../utils/app_logger.dart';
import '../utils/helper.dart';
import '../utils/utils.dart';

class LectureDetailScreen extends StatelessWidget {
  final String sessionId;

  const LectureDetailScreen({
    super.key,
    required this.sessionId,
  });

  String _formatTranscriptStatus(
    BuildContext context,
    String status,
  ) {
    final strings = AppLocalizations.of(context);

    switch (status.toLowerCase()) {
      case 'done':
        return strings.transcriptReady;
      case 'processing':
        return strings.transcriptProcessing;
      case 'pending':
        return strings.transcriptQueued;
      case 'error':
        return strings.transcriptFailed;
      case 'none':
      case '':
        return strings.noTranscript;
      default:
        return status;
    }
  }

  Future<void> _viewAiOutput(
    BuildContext context,
    String sessionId,
    String type,
    String className,
    String topic,
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
            title: Text(AppLocalizations.of(context).noAiOutputTitle),
            content: Text(AppLocalizations.of(context).noAiOutputMessage),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(AppLocalizations.of(context).ok),
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

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AiOutputScreen(
            sessionId: sessionId,
            type: type,
            data: parsed,
            className: className,
            topic: topic,
          ),
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
          title: Text(AppLocalizations.of(context).aiOutputError),
          content: Text(AppLocalizations.of(context).aiOutputLoadFailed),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(AppLocalizations.of(context).ok),
            ),
          ],
        ),
      );
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
    final strings = AppLocalizations.of(context);
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
    final strings = AppLocalizations.of(context);

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
                      if (levelName.isNotEmpty)
                        Text(strings.levelValue(levelName)),
                      if (semesterName.isNotEmpty)
                        Text(strings.semesterValue(semesterName)),
                      if (filename.isNotEmpty)
                        Text(strings.fileValue(filename)),
                      Text(
                        strings.durationValue(
                          formatDuration(
                            Duration(seconds: durationSeconds),
                          ),
                        ),
                      ),
                      Text(
                        strings.transcriptStatusValue(
                          _formatTranscriptStatus(context, transcriptStatus),
                        ),
                      ),
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
                    if (playbackSnap.connectionState ==
                        ConnectionState.waiting) {
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
                          content: Text(strings.transcriptLoadFailed),
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
                          SnackBar(
                              content: Text(strings.transcriptionRequested)),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text(strings.requestTranscriptionFailed)),
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
              if (transcriptStatus != 'done') ...[
                const SizedBox(height: 8),
                Text(
                  strings.transcriptionRequiredForAi,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
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
                viewAiOutput: (context, sessionId, type) => _viewAiOutput(
                  context,
                  sessionId,
                  type,
                  className,
                  topic,
                ),
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
                viewAiOutput: (context, sessionId, type) => _viewAiOutput(
                  context,
                  sessionId,
                  type,
                  className,
                  topic,
                ),
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
                viewAiOutput: (context, sessionId, type) => _viewAiOutput(
                  context,
                  sessionId,
                  type,
                  className,
                  topic,
                ),
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

  String _formatAiOutputStatus(
    BuildContext context,
    String status,
  ) {
    final strings = AppLocalizations.of(context);

    switch (status.toLowerCase()) {
      case 'done':
        return strings.aiReady;
      case 'processing':
        return strings.transcriptProcessing;
      case 'pending':
        return strings.aiQueued;
      case 'error':
        return strings.transcriptFailed;
      case 'none':
      case '':
        return strings.aiNotStartedLabel;
      default:
        return status;
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return ListTile(
      leading: const Icon(Icons.auto_awesome),
      title: Text(title),
      subtitle: Text(
        strings.statusValue(
          _formatAiOutputStatus(context, status),
        ),
      ),
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
