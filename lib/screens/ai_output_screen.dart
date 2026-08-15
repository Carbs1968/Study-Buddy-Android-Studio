import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import '../utils/utils.dart';
import 'lecture_chat_screen.dart';

class AiOutputScreen extends StatefulWidget {
  final String sessionId;
  final String type;
  final Map<String, dynamic> data;
  final String className;
  final String topic;
  final String? revisionCandidateId;

  const AiOutputScreen({
    super.key,
    required this.sessionId,
    required this.type,
    required this.data,
    required this.className,
    required this.topic,
    this.revisionCandidateId,
  });

  @override
  State<AiOutputScreen> createState() => _AiOutputScreenState();
}

class _AiOutputScreenState extends State<AiOutputScreen> {
  late Map<String, dynamic> _data;
  bool _replacing = false;

  @override
  void initState() {
    super.initState();
    _data = Map<String, dynamic>.from(widget.data);
  }

  String _title(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return switch (widget.type) {
      'summary' => strings.aiSummaryTitle,
      'notes' => strings.aiNotesTitle,
      'quiz' => strings.aiQuizTitle,
      _ => strings.aiOutputs,
    };
  }

  Future<void> _copyOutput(BuildContext context) async {
    final strings = AppLocalizations.of(context);
    final prettyJson = const JsonEncoder.withIndent('  ').convert(_data);

    await Clipboard.setData(ClipboardData(text: prettyJson));

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(strings.copiedJsonToClipboard),
      ),
    );
  }

  Widget _buildOutput(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);

    switch (widget.type) {
      case 'summary':
        final summary = _data['summary'];
        final title = _data['title'];
        final abstract = _data['abstract'];
        final keyPoints = List<String>.from(_data['key_points'] ?? const []);
        final terms = List<String>.from(_data['terms'] ?? const []);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              Text(
                title.toString(),
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
            ],
            if (summary != null)
              SelectableText(
                summary.toString(),
                style: theme.textTheme.bodyLarge,
              ),
            if (abstract != null) ...[
              const SizedBox(height: 16),
              SelectableText(
                abstract.toString(),
                style: theme.textTheme.bodyLarge,
              ),
            ],
            if (keyPoints.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                strings.keyPoints,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ...keyPoints.map(
                (point) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('• $point'),
                ),
              ),
            ],
            if (terms.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                strings.terms,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ...terms.map(
                (term) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Text('• $term'),
                ),
              ),
            ],
          ],
        );

      case 'notes':
        final rawNotes = _data['notes'] ?? _data['outline'] ?? const [];
        final outline = List<Map<String, dynamic>>.from(
          (rawNotes as List).map(
            (item) => Map<String, dynamic>.from(item as Map),
          ),
        );
        final equations = List<String>.from(_data['equations'] ?? const []);
        final references = List<String>.from(_data['references'] ?? const []);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final section in outline) ...[
              Text(
                section['heading']?.toString() ?? '',
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ...List<String>.from(section['bullets'] ?? const []).map(
                (bullet) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('• $bullet'),
                ),
              ),
              const SizedBox(height: 20),
            ],
            if (equations.isNotEmpty) ...[
              Text(
                strings.equations,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ...equations.map(
                (equation) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: SelectableText(equation),
                ),
              ),
            ],
            if (references.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                strings.references,
                style: theme.textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              ...references.map(
                (reference) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: SelectableText(reference),
                ),
              ),
            ],
          ],
        );

      case 'quiz':
        final questions = List<Map<String, dynamic>>.from(
          (_data['questions'] as List? ?? const []).map(
            (item) => Map<String, dynamic>.from(item as Map),
          ),
        );

        return Column(
          children: [
            for (var index = 0; index < questions.length; index++) ...[
              Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${index + 1}. '
                        '${(questions[index]['question'] ?? questions[index]['prompt'] ?? '').toString()}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      if ((questions[index]['choices'] as List?)?.isNotEmpty ??
                          false) ...[
                        const SizedBox(height: 12),
                        ...List<String>.from(
                          questions[index]['choices'] ?? const [],
                        ).map(
                          (choice) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: Text('○ $choice'),
                          ),
                        ),
                      ],
                      const SizedBox(height: 14),
                      Text(
                        strings.answerValue(
                          questions[index]['answer']?.toString() ?? '',
                        ),
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (questions[index]['explanation'] != null ||
                          questions[index]['rationale'] != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          strings.whyValue(
                            (questions[index]['explanation'] ??
                                    questions[index]['rationale'])
                                .toString(),
                          ),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ],
        );

      default:
        return SelectableText(_data.toString());
    }
  }

  String _replaceLabel(AppLocalizations strings) {
    return switch (widget.type) {
      'summary' => strings.replaceSummary,
      'notes' => strings.replaceNotes,
      'quiz' => strings.replacePracticeTest,
      _ => strings.replaceSummary,
    };
  }

  String _replaceConfirmBody(AppLocalizations strings) {
    return switch (widget.type) {
      'summary' => strings.replaceSummaryConfirmBody,
      'notes' => strings.replaceNotesConfirmBody,
      'quiz' => strings.replacePracticeTestConfirmBody,
      _ => strings.replaceSummaryConfirmBody,
    };
  }

  Future<Map<String, dynamic>?> _replaceRevision(
    BuildContext context,
  ) async {
    final candidateId = widget.revisionCandidateId;
    if (candidateId == null || candidateId.isEmpty || _replacing) {
      return null;
    }

    final strings = AppLocalizations.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.replaceArtifactConfirmTitle),
        content: Text(_replaceConfirmBody(strings)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(strings.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(strings.confirm),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return null;

    setState(() {
      _replacing = true;
    });

    try {
      final callable = functions.httpsCallable('replaceLectureArtifact');
      final result = await callable.call({
        'candidateId': candidateId,
      });

      final resultData = result.data as Map?;
      final rawOutput = resultData?['data'];

      if (!context.mounted || rawOutput is! Map) return null;

      final output = Map<String, dynamic>.from(rawOutput);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.replaceArtifactSuccess)),
      );

      return output;
    } catch (_) {
      if (!context.mounted) return null;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.replaceArtifactError)),
      );

      return null;
    } finally {
      if (mounted) {
        setState(() {
          _replacing = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final contextLabel = [
      if (widget.className.trim().isNotEmpty) widget.className.trim(),
      if (widget.topic.trim().isNotEmpty) widget.topic.trim(),
    ].join(' • ');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.revisionCandidateId == null
              ? _title(context)
              : strings.revisionPreviewTitle,
        ),
        actions: [
          IconButton(
            tooltip: strings.copy,
            onPressed: () => _copyOutput(context),
            icon: const Icon(Icons.copy_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 800),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              children: [
                if (contextLabel.isNotEmpty) ...[
                  Text(
                    contextLabel,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 16),
                ],
                _buildOutput(context),
                const SizedBox(height: 28),
                if (widget.revisionCandidateId == null)
                  FilledButton.icon(
                    onPressed: () async {
                      final revision = await Navigator.of(context)
                          .push<Map<String, dynamic>>(
                        MaterialPageRoute<Map<String, dynamic>>(
                          builder: (_) => LectureChatScreen(
                            sessionId: widget.sessionId,
                            artifactType: widget.type,
                            className: widget.className,
                            topic: widget.topic,
                          ),
                        ),
                      );

                      if (!context.mounted || revision == null) return;

                      final candidateId =
                          revision['candidateId']?.toString() ?? '';
                      final rawCandidate = revision['data'];

                      if (candidateId.isEmpty || rawCandidate is! Map) return;

                      final replaced = await Navigator.of(context)
                          .push<Map<String, dynamic>>(
                        MaterialPageRoute<Map<String, dynamic>>(
                          builder: (_) => AiOutputScreen(
                            sessionId: widget.sessionId,
                            type: widget.type,
                            data: Map<String, dynamic>.from(rawCandidate),
                            className: widget.className,
                            topic: widget.topic,
                            revisionCandidateId: candidateId,
                          ),
                        ),
                      );

                      if (replaced != null && mounted) {
                        setState(() {
                          _data = Map<String, dynamic>.from(replaced);
                        });
                      }
                    },
                    icon: const Icon(Icons.chat_bubble_outline),
                    label: Text(strings.askAi),
                  )
                else
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton(
                        onPressed: _replacing
                            ? null
                            : () async {
                                final output = await _replaceRevision(context);
                                if (output != null && context.mounted) {
                                  Navigator.of(context).pop(output);
                                }
                              },
                        child: _replacing
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                _replaceLabel(strings),
                                textAlign: TextAlign.center,
                              ),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: _replacing
                            ? null
                            : () => Navigator.of(context).pop(),
                        child: Text(
                          strings.cancel,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
