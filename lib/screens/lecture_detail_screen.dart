// ---------------------------
// Lecture Detail (safe reads + Drive playback preference)
// ---------------------------

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/strings.dart';
import '../utils/app_logger.dart';
import '../utils/utils.dart';


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
    final uid = FirebaseAuth.instance.currentUser?.uid;
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

        final strings = SBStrings.of(context);
        return Scaffold(
          appBar: AppBar(title: Text('$className — $topic')),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Playback (Drive preferred, Storage fallback) — button only
              Text(strings.playback, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Builder(
                builder: (context) {
                  Future<void> _open(String url) async {
                    final uri = Uri.parse(url);
                    if (!await launchUrl(uri,
                        mode: LaunchMode.externalApplication)) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(strings.couldNotOpenLink)),
                      );
                    }
                  }

                  if (driveViewUrl.isNotEmpty) {
                    return ElevatedButton(
                      onPressed: () => _open(driveViewUrl),
                      child: Text(strings.openInGoogleDrive),
                    );
                  }

                  if (storageUrl.isNotEmpty) {
                    return ElevatedButton(
                      onPressed: () => _open(storageUrl),
                      child: Text(strings.openFromFirebaseStorage),
                    );
                  }

                  return Text(
                    strings.noPlaybackLinkAvailable,
                    style: const TextStyle(color: Colors.black54),
                  );
                },
              ),
              const SizedBox(height: 16),
              const Divider(),

              ListTile(
                leading: const Icon(Icons.description),
                title: Text(strings.transcriptStatus),
                subtitle: Text(status),
              ),

              // Show “View transcript” when done (private fetch via callable)
              if (status == 'done') ...[
                const SizedBox(height: 8),
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
                      final full = await fetchTranscript(recordingId);
                      Navigator.of(context).pop(); // close progress
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
                      if (Navigator.of(context).canPop()) {
                        Navigator.of(context).pop(); // ensure spinner closes on error
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
              ],

              const SizedBox(height: 8),
              if (status == 'none' || status == 'error')
                ElevatedButton.icon(
                  icon: const Icon(Icons.text_snippet_outlined),
                  label: Text(strings.requestTranscription),
                  onPressed: () async {
                    try {
                      await docRef.update({
                        'transcribeRequested': true,
                        'transcriptStatus': 'pending',
                      });
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(strings.transcriptionRequested)),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('${strings.failed}: $e')),
                      );
                    }
                  },
                ),

              if (transcriptId != null)
                ListTile(
                  leading: const Icon(Icons.article),
                  title: Text(strings.transcriptGoogleDrive),
                  subtitle: Text('${strings.fileId}: $transcriptId'),
                ),

              for (final id in subs)
                ListTile(
                  leading: const Icon(Icons.subtitles),
                  title: Text(strings.subtitlesGoogleDrive),
                  subtitle: Text('${strings.fileId}: $id'),
                ),

              const SizedBox(height: 24),
              const Divider(),
              Text(strings.aiOutputs, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),

              _AiActionRow(
                title: strings.generateSummary,
                status: (m['summaryStatus'] ?? 'none').toString(),
                onRequest: () async {
                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  debugPrint("::::::${uid}");
                  try {
                    await FirebaseFirestore.instance.collection('aiJobs').add({
                      'uid': uid,
                      'type': 'summary',
                      'recordingId': recordingId,
                      'status': 'pending',
                      'createdAt': DateTime.now().toIso8601String(),
                    });
                    debugPrint('Document successfully written!');
                  } on FirebaseException catch (e) {
                    debugPrint('Error writing document: ${e.code} - ${e.message}');
                    // Handle specific FirebaseException codes, e.g., permission-denied
                    if (e.code == 'permission-denied') {
                      // Show a user-friendly message or log the error
                    }
                  } catch (e) {
                    debugPrint('An unexpected error occurred: $e');
                  }
                },
                recordingId: recordingId,
                viewAiOutput: _viewAiOutput,
              ),
              _AiActionRow(
                title: strings.generateNotes,
                status: (m['notesStatus'] ?? 'none').toString(),
                onRequest: () async {
                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  await FirebaseFirestore.instance.collection('aiJobs').add({
                    'uid': uid,
                    'type': 'notes',
                    'recordingId': recordingId,
                    'status': 'pending',
                    'createdAt': DateTime.now().toIso8601String(),
                  });
                },
                recordingId: recordingId,
                viewAiOutput: _viewAiOutput,
              ),
              _AiActionRow(
                title: strings.generatePracticeTest,
                status: (m['quizStatus'] ?? 'none').toString(),
                onRequest: () async {
                  final uid = FirebaseAuth.instance.currentUser?.uid;
                  await FirebaseFirestore.instance.collection('aiJobs').add({
                    'uid': uid,
                    'type': 'quiz',
                    'recordingId': recordingId,
                    'status': 'pending',
                    'createdAt': DateTime.now().toIso8601String(),
                  });
                },
                recordingId: recordingId,
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
  final String status;
  final Future<void> Function() onRequest;
  final String recordingId;
  final Future<void> Function(BuildContext, String, String)? viewAiOutput;

  const _AiActionRow({
    required this.title,
    required this.status,
    required this.onRequest,
    required this.recordingId,
    this.viewAiOutput,
  });

  String _typeFromTitle(String t) {
    final lower = t.toLowerCase();
    if (lower.contains('summary')) return 'summary';
    if (lower.contains('notes')) return 'notes';
    if (lower.contains('practice') || lower.contains('quiz')) return 'quiz';
    return '';
  }

  @override
  Widget build(BuildContext context) {
    final type = _typeFromTitle(title);
    final strings = SBStrings.of(context);
    return ListTile(
      leading: const Icon(Icons.auto_awesome),
      title: Text(title),
      subtitle: Text('${strings.status}: $status'),
      trailing: ElevatedButton(
        onPressed: (status == 'none' || status == 'error')
            ? onRequest
            : (status == 'done' && viewAiOutput != null && type.isNotEmpty
            ? () => viewAiOutput!(context, recordingId, type)
            : null),
        child: Text(
          (status == 'done') ? strings.view : strings.request,
        ),
      ),
    );
  }
}