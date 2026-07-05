import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ClassStudyGuideScreen extends StatelessWidget {
  const ClassStudyGuideScreen({
    super.key,
    required this.academicYearId,
    required this.semesterId,
    required this.classId,
    required this.guideId,
    required this.className,
  });

  final String academicYearId;
  final String semesterId;
  final String classId;
  final String guideId;
  final String className;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final theme = Theme.of(context);

    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Not signed in')),
      );
    }

    final guideRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('academicYears')
        .doc(academicYearId)
        .collection('semesters')
        .doc(semesterId)
        .collection('classes')
        .doc(classId)
        .collection('studyGuides')
        .doc(guideId);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('$className Study Guide'),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: guideRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Could not load study guide.'));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final doc = snapshot.data!;
          if (!doc.exists) {
            return const Center(child: Text('Study guide not found.'));
          }

          final data = doc.data() ?? {};
          final output = (data['output'] as Map?)?.cast<String, dynamic>() ?? {};
          final title = (output['title'] ?? 'Class Study Guide').toString();
          final overview = (output['overview'] ?? '').toString();
          final keyTopics =
              ((output['keyTopics'] as List?) ?? const <dynamic>[])
                  .whereType<Map>()
                  .map((e) => e.cast<String, dynamic>())
                  .toList();
          final sections =
              ((output['studySections'] as List?) ?? const <dynamic>[])
                  .whereType<Map>()
                  .map((e) => e.cast<String, dynamic>())
                  .toList();
          final questions =
              ((output['reviewQuestions'] as List?) ?? const <dynamic>[])
                  .whereType<Map>()
                  .map((e) => e.cast<String, dynamic>())
                  .toList();

          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              Text(
                title,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Generated from completed class transcripts.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (overview.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(overview, style: theme.textTheme.bodyLarge),
              ],
              const SizedBox(height: 24),
              _SectionTitle('Key topics'),
              ...keyTopics.map(
                (topic) => _GuideCard(
                  title: (topic['title'] ?? '').toString(),
                  body: (topic['summary'] ?? '').toString(),
                ),
              ),
              const SizedBox(height: 12),
              _SectionTitle('Study sections'),
              ...sections.map(
                (section) {
                  final bullets = ((section['bullets'] as List?) ??
                          const <dynamic>[])
                      .map((e) => e.toString())
                      .where((e) => e.trim().isNotEmpty)
                      .toList();
                  return _GuideCard(
                    title: (section['heading'] ?? '').toString(),
                    bullets: bullets,
                  );
                },
              ),
              const SizedBox(height: 12),
              _SectionTitle('Review questions'),
              ...questions.map(
                (question) => _GuideCard(
                  title: (question['question'] ?? '').toString(),
                  body: (question['answer'] ?? '').toString(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({
    required this.title,
    this.body,
    this.bullets = const [],
  });

  final String title;
  final String? body;
  final List<String> bullets;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.cardColor,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title.trim().isNotEmpty)
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            if ((body ?? '').trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(body!),
            ],
            if (bullets.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...bullets.map(
                (bullet) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text('• $bullet'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
