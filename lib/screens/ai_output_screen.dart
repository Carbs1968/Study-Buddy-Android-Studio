import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_localizations.dart';
import 'lecture_chat_screen.dart';

class AiOutputScreen extends StatelessWidget {
  final String sessionId;
  final String type;
  final Map<String, dynamic> data;
  final String className;
  final String topic;

  const AiOutputScreen({
    super.key,
    required this.sessionId,
    required this.type,
    required this.data,
    required this.className,
    required this.topic,
  });

  String _title(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return switch (type) {
      'summary' => strings.aiSummaryTitle,
      'notes' => strings.aiNotesTitle,
      'quiz' => strings.aiQuizTitle,
      _ => strings.aiOutputs,
    };
  }

  Future<void> _copyOutput(BuildContext context) async {
    final strings = AppLocalizations.of(context);
    final prettyJson = const JsonEncoder.withIndent('  ').convert(data);

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
        final rawNotes = data['notes'] ?? data['outline'] ?? const [];
        final outline = List<Map<String, dynamic>>.from(
          (rawNotes as List).map(
            (item) => Map<String, dynamic>.from(item as Map),
          ),
        );
        final equations = List<String>.from(data['equations'] ?? const []);
        final references = List<String>.from(data['references'] ?? const []);

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
          (data['questions'] as List? ?? const []).map(
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
        return SelectableText(data.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);

    final contextLabel = [
      if (className.trim().isNotEmpty) className.trim(),
      if (topic.trim().isNotEmpty) topic.trim(),
    ].join(' • ');

    return Scaffold(
      appBar: AppBar(
        title: Text(_title(context)),
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
                FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => LectureChatScreen(
                          sessionId: sessionId,
                          artifactType: type,
                          className: className,
                          topic: topic,
                        ),
                      ),
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: Text(strings.askAi),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
