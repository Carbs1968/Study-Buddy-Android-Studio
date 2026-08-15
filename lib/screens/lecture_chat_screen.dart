import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../utils/utils.dart';

class LectureChatScreen extends StatefulWidget {
  final String sessionId;
  final String artifactType;
  final String className;
  final String topic;

  const LectureChatScreen({
    super.key,
    required this.sessionId,
    required this.artifactType,
    required this.className,
    required this.topic,
  });

  @override
  State<LectureChatScreen> createState() => _LectureChatScreenState();
}

class _LectureChatScreenState extends State<LectureChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Map<String, String>> _messages = [];

  bool _sending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _sendMessage() async {
    final question = _controller.text.trim();

    if (question.isEmpty || _sending) {
      return;
    }

    final strings = AppLocalizations.of(context);

    final history = _messages
        .map(
          (message) => {
            'role': message['role'] ?? 'user',
            'content': message['content'] ?? '',
          },
        )
        .toList();

    setState(() {
      _messages.add({
        'role': 'user',
        'content': question,
      });
      _sending = true;
      _controller.clear();
    });

    _scrollToBottom();

    try {
      final callable = functions.httpsCallable('askLectureAi');

      final result = await callable.call({
        'sessionId': widget.sessionId,
        'artifactType': widget.artifactType,
        'question': question,
        'history': history,
      });

      final data = result.data as Map?;
      final answer = data?['answer']?.toString().trim() ?? '';

      if (!mounted) return;

      if (answer.isEmpty) {
        throw StateError('Empty AI response');
      }

      setState(() {
        _messages.add({
          'role': 'assistant',
          'content': answer,
        });
      });

      _scrollToBottom();
    } catch (_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.lectureChatError),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _sending = false;
        });
      }
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Widget _messageBubble(
    BuildContext context,
    Map<String, String> message,
  ) {
    final theme = Theme.of(context);
    final isUser = message['role'] == 'user';

    final backgroundColor = isUser
        ? theme.colorScheme.primaryContainer
        : theme.colorScheme.surfaceContainerHighest;

    final foregroundColor = isUser
        ? theme.colorScheme.onPrimaryContainer
        : theme.colorScheme.onSurface;

    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 680),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(18),
        ),
        child: SelectableText(
          message['content'] ?? '',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: foregroundColor,
          ),
        ),
      ),
    );
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
        title: Text(strings.lectureChatTitle),
      ),
      body: SafeArea(
        child: Column(
          children: [
            if (contextLabel.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
                child: Text(
                  contextLabel,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            Expanded(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 800),
                  child: _messages.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.all(24),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: theme.colorScheme.primary,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  strings.lectureChatTemporaryTitle,
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  switch (widget.artifactType) {
                                    'summary' =>
                                      strings.lectureChatTemporarySummaryBody,
                                    'notes' =>
                                      strings.lectureChatTemporaryNotesBody,
                                    'quiz' =>
                                      strings.lectureChatTemporaryQuizBody,
                                    _ => strings.lectureChatTemporaryBody,
                                  },
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            return _messageBubble(
                              context,
                              _messages[index],
                            );
                          },
                        ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: theme.colorScheme.outlineVariant,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      enabled: !_sending,
                      minLines: 1,
                      maxLines: 5,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        hintText: strings.lectureChatHint,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: strings.send,
                    onPressed: _sending ? null : _sendMessage,
                    icon: _sending
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.send_rounded),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
