import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../class_lectures_screen.dart';

import '../../../l10n/strings.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({
    super.key,
    this.onRecordTap,
    this.onUploadMaterialTap,
  });

  final VoidCallback? onRecordTap;
  final VoidCallback? onUploadMaterialTap;

  @override
  Widget build(BuildContext context) {
    final strings = SBStrings.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
          children: [
            Text(
              strings.appTitle,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Your study workspace, organized by class and topic.',
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            const _AcademicContextCard(),
            const SizedBox(height: 20),
            Text(
              'Quick actions',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            _DashboardActionCard(
              icon: Icons.mic_none,
              title: strings.record,
              subtitle: 'Start a new classroom recording.',
              onTap: onRecordTap,
            ),
            const SizedBox(height: 12),
            _DashboardActionCard(
              icon: Icons.upload_file_outlined,
              title: 'Upload Study Material',
              subtitle: 'Choose a class or topic before uploading.',
              onTap: onUploadMaterialTap,
            ),
            const SizedBox(height: 24),
            Text(
              'Recent Classes',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            const _RecentClassesSection(),
          ],
        ),
      ),
    );
  }
}

class _AcademicContextCard extends StatelessWidget {
  const _AcademicContextCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            const Icon(Icons.school_outlined, size: 32),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Academic context',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Year → Semester → Class → Topic',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
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

class _DashboardActionCard extends StatelessWidget {
  const _DashboardActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        onTap: onTap,
        minVerticalPadding: 18,
        leading: Icon(
          icon,
          color: theme.colorScheme.primary,
        ),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            color: null,
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

class _RecentClassesSection extends StatelessWidget {
  const _RecentClassesSection();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const _EmptyStateCard();
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('sessions')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const _DashboardMessageCard(
            icon: Icons.warning_amber_outlined,
            title: 'Could not load recent classes',
            message: 'Check your connection and try again.',
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _DashboardMessageCard(
            icon: Icons.hourglass_empty,
            title: 'Loading recent classes',
            message: 'Checking your latest study activity...',
          );
        }

        final rows = _buildRecentClassRows(snapshot.data?.docs ?? const []);
        if (rows.isEmpty) {
          return const _EmptyStateCard();
        }

        return Column(
          children: [
            for (final row in rows.take(5)) ...[
              _RecentClassCard(row: row),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}

class _RecentClassCard extends StatelessWidget {
  const _RecentClassCard({required this.row});

  final _RecentClassRow row;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final latest = row.latest;
    final sessionsLabel =
        '${row.sessionCount} session${row.sessionCount == 1 ? '' : 's'}';
    final activityLabel = latest == null
        ? sessionsLabel
        : '$sessionsLabel • ${_formatRecentDate(latest)}';

    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: Icon(
          Icons.menu_book_outlined,
          color: theme.colorScheme.primary,
        ),
        title: Text(
          row.className,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        subtitle: Text(
          activityLabel,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ClassLecturesScreen(
                className: row.className,
                academicYearId: row.academicYearId,
                semesterId: row.semesterId,
                classId: row.classId,
                useStableSessionQuery: row.useStableSessionQuery,
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DashboardMessageCard extends StatelessWidget {
  const _DashboardMessageCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 30, color: theme.colorScheme.primary),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
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

List<_RecentClassRow> _buildRecentClassRows(
  List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
) {
  final rows = <String, _RecentClassRow>{};

  for (final doc in docs) {
    final data = doc.data();
    final className = (data['className'] ?? '').toString().trim();
    if (className.isEmpty) {
      continue;
    }

    final storedAcademicYearId =
        (data['academicYearId'] ?? '').toString().trim();
    final storedSemesterId = (data['semesterId'] ?? '').toString().trim();
    final storedClassId = (data['classId'] ?? '').toString().trim();

    final hasStableContext = storedAcademicYearId.isNotEmpty &&
        storedSemesterId.isNotEmpty &&
        storedClassId.isNotEmpty;

    final academicYearName =
        (data['academicYearName'] ?? data['levelName'] ?? 'legacy')
            .toString()
            .trim();
    final semesterName =
        (data['semesterName'] ?? 'legacy-term').toString().trim();

    final academicYearId = hasStableContext
        ? storedAcademicYearId
        : _stableDocumentId(academicYearName);
    final semesterId =
        hasStableContext ? storedSemesterId : _stableDocumentId(semesterName);
    final classId =
        hasStableContext ? storedClassId : _stableDocumentId(className);

    final key = '$academicYearId/$semesterId/$classId';
    final row = rows.putIfAbsent(
      key,
      () => _RecentClassRow(
        className: className,
        academicYearId: academicYearId,
        semesterId: semesterId,
        classId: classId,
        useStableSessionQuery: hasStableContext,
      ),
    );

    row.sessionCount += 1;

    final latest = _extractSessionDate(data);
    if (latest != null && (row.latest == null || latest.isAfter(row.latest!))) {
      row.latest = latest;
    }
  }

  final sorted = rows.values.toList()
    ..sort((a, b) {
      final aLatest = a.latest;
      final bLatest = b.latest;

      if (aLatest != null && bLatest != null) {
        final byDate = bLatest.compareTo(aLatest);
        if (byDate != 0) {
          return byDate;
        }
      } else if (aLatest != null) {
        return -1;
      } else if (bLatest != null) {
        return 1;
      }

      return b.sessionCount.compareTo(a.sessionCount);
    });

  return sorted;
}

DateTime? _extractSessionDate(Map<String, dynamic> data) {
  for (final key in ['updatedAt', 'completedAt', 'createdAt', 'startedAt']) {
    final date = _toDateTime(data[key]);
    if (date != null) {
      return date;
    }
  }
  return null;
}

DateTime? _toDateTime(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }
  if (value is DateTime) {
    return value;
  }
  if (value is String) {
    return DateTime.tryParse(value);
  }
  return null;
}

String _formatRecentDate(DateTime date) {
  final days = DateTime.now().difference(date).inDays;
  if (days <= 0) {
    return 'Today';
  }
  if (days == 1) {
    return 'Yesterday';
  }
  if (days < 7) {
    return '$days days ago';
  }

  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '${date.year}-$month-$day';
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

  return slug.isEmpty ? 'legacy' : slug;
}

class _RecentClassRow {
  _RecentClassRow({
    required this.className,
    required this.academicYearId,
    required this.semesterId,
    required this.classId,
    required this.useStableSessionQuery,
  });

  final String className;
  final String academicYearId;
  final String semesterId;
  final String classId;
  final bool useStableSessionQuery;
  int sessionCount = 0;
  DateTime? latest;
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.cardColor,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.folder_open_outlined,
              size: 34,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 12),
            Text(
              'Recent classes will appear here',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Record a class session to see your most recent study activity here.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
