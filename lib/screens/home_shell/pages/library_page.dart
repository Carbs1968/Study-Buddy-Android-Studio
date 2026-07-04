import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../l10n/strings.dart';
import '../../class_lectures_screen.dart';

class LibraryPage extends StatefulWidget {
  const LibraryPage({super.key});

  @override
  State<LibraryPage> createState() => _LibraryPageState();
}

class _LibraryPageState extends State<LibraryPage> {
  String _search = '';

  DateTime? _toDt(dynamic v) {
    if (v is Timestamp) return v.toDate();
    if (v is String) return DateTime.tryParse(v);
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final strings = SBStrings.of(context);
    final theme = Theme.of(context);

    if (uid == null) {
      return Scaffold(
        body: Center(child: Text(strings.notSignedIn)),
      );
    }

    final q = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('sessions');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(strings.library),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                filled: true,
                fillColor: theme.colorScheme.surface,
                prefixIcon: const Icon(Icons.search),
                hintText: strings.selectClass,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Theme.of(context).colorScheme.primary,
                    width: 1.5,
                  ),
                ),
              ),
              onChanged: (v) => setState(() => _search = v.trim().toLowerCase()),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: q.snapshots(),
              builder: (ctx, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        '${strings.errorLoading}: ${snap.error}',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final docs = snap.data?.docs ?? [];
                if (docs.isEmpty) {
                  return _LibraryEmptyState(
                    message: strings.noRecordingsYet,
                    helper:
                        'Record a lecture from the Recorder tab to build your Library.',
                  );
                }

                final Map<String, _ClassRow> classes = {};

                for (final d in docs) {
                  final m = d.data();
                  final className = (m['className'] ?? '').toString().trim();
                  if (className.isEmpty) continue;

                  final createdAt = _toDt(m['createdAt']);
                  final storedAcademicYearId =
                      (m['academicYearId'] ?? '').toString().trim();
                  final storedSemesterId =
                      (m['semesterId'] ?? '').toString().trim();
                  final storedClassId = (m['classId'] ?? '').toString().trim();

                  final hasStoredStableContext = storedAcademicYearId.isNotEmpty &&
                      storedSemesterId.isNotEmpty &&
                      storedClassId.isNotEmpty;

                  final academicYearName =
                      (m['academicYearName'] ?? m['levelName'] ?? 'legacy')
                          .toString()
                          .trim();
                  final semesterName =
                      (m['semesterName'] ?? 'legacy-term').toString().trim();

                  final academicYearId = hasStoredStableContext
                      ? storedAcademicYearId
                      : _stableDocumentId(academicYearName);
                  final semesterId = hasStoredStableContext
                      ? storedSemesterId
                      : _stableDocumentId(semesterName);
                  final classId = hasStoredStableContext
                      ? storedClassId
                      : _stableDocumentId(className);

                  final classKey = '$academicYearId/$semesterId/$classId';

                  final row = classes.putIfAbsent(
                    classKey,
                    () => _ClassRow(
                      className: className,
                      academicYearId: academicYearId,
                      semesterId: semesterId,
                      classId: classId,
                      useStableSessionQuery: hasStoredStableContext,
                    ),
                  );
                  row.count += 1;

                  if (createdAt != null &&
                      (row.latest == null || createdAt.isAfter(row.latest!))) {
                    row.latest = createdAt;
                  }
                }

                var items = classes.values
                    .where((r) =>
                _search.isEmpty || r.className.toLowerCase().contains(_search))
                    .toList();

                items.sort((a, b) {
                  final la = a.latest;
                  final lb = b.latest;

                  if (la == null && lb == null) {
                    return a.className.compareTo(b.className);
                  }
                  if (la == null) return 1;
                  if (lb == null) return -1;

                  final cmp = lb.compareTo(la);
                  if (cmp != 0) return cmp;

                  return a.className.compareTo(b.className);
                });

                if (items.isEmpty) {
                  return _LibraryEmptyState(
                    message: strings.noClassesMatch,
                    helper: 'Try a different class name or clear the search.',
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final r = items[i];

                    final latest = r.latest?.toLocal();
                    final latestLabel = latest == null
                        ? null
                        : 'Latest: ${const [
                            'Jan',
                            'Feb',
                            'Mar',
                            'Apr',
                            'May',
                            'Jun',
                            'Jul',
                            'Aug',
                            'Sep',
                            'Oct',
                            'Nov',
                            'Dec',
                          ][latest.month - 1]} ${latest.day}, ${latest.year}';

                    final subtitleParts = <String>[
                      if (latestLabel != null) latestLabel,
                      strings.lectureCount(r.count),
                    ];

                    return Card(
                      elevation: 0,
                      color: theme.cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        leading: Icon(
                          Icons.folder_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(
                          r.className,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                        ),
                        subtitle: Text(
                          subtitleParts.join(' • '),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ClassLecturesScreen(
                                className: r.className,
                                academicYearId: r.academicYearId,
                                semesterId: r.semesterId,
                                classId: r.classId,
                                useStableSessionQuery: r.useStableSessionQuery,
                              ),
                            ),
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


class _LibraryEmptyState extends StatelessWidget {
  const _LibraryEmptyState({
    required this.message,
    this.helper,
  });

  final String message;
  final String? helper;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 0,
          color: theme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.folder_open_outlined,
                  size: 42,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(height: 12),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (helper != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    helper!,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
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

  return slug.isEmpty ? 'legacy' : slug;
}

class _ClassRow {
  final String className;
  final String academicYearId;
  final String semesterId;
  final String classId;
  final bool useStableSessionQuery;
  int count = 0;
  DateTime? latest;

  _ClassRow({
    required this.className,
    required this.academicYearId,
    required this.semesterId,
    required this.classId,
    required this.useStableSessionQuery,
  });
}
