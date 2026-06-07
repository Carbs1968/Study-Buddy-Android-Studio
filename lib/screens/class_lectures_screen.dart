import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import '../utils/helper.dart';
import 'class_materials_screen.dart';
import 'lecture_detail_screen.dart';

class ClassLecturesScreen extends StatefulWidget {
  final String className;
  final String academicYearId;
  final String semesterId;
  final String classId;
  final bool useStableSessionQuery;

  const ClassLecturesScreen({
    super.key,
    required this.className,
    this.academicYearId = '',
    this.semesterId = '',
    this.classId = '',
    this.useStableSessionQuery = false,
  });

  @override
  State<ClassLecturesScreen> createState() => _ClassLecturesScreenState();
}

class _ClassLecturesScreenState extends State<ClassLecturesScreen> {
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

    if (uid == null) {
      return Scaffold(
        body: Center(child: Text(strings.notSignedIn)),
      );
    }

    final hasStableClassContext = widget.academicYearId.trim().isNotEmpty &&
        widget.semesterId.trim().isNotEmpty &&
        widget.classId.trim().isNotEmpty;

    final useStableSessionQuery =
        widget.useStableSessionQuery && hasStableClassContext;

    final q = useStableSessionQuery
        ? FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('sessions')
            .where('academicYearId', isEqualTo: widget.academicYearId)
            .where('semesterId', isEqualTo: widget.semesterId)
            .where('classId', isEqualTo: widget.classId)
        : FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('sessions')
            .where('className', isEqualTo: widget.className);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FB),
      appBar: AppBar(
        title: Text(widget.className),
        backgroundColor: const Color(0xFFF6F8FB),
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Materials',
            icon: const Icon(Icons.folder_copy_outlined),
            onPressed: hasStableClassContext
                ? () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ClassMaterialsScreen(
                          academicYearId: widget.academicYearId,
                          semesterId: widget.semesterId,
                          classId: widget.classId,
                          className: widget.className,
                        ),
                      ),
                    );
                  }
                : null,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.search),
                hintText: '${strings.lectureTopic}...',
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

                var docs = (snap.data?.docs ?? []).toList();

                docs = docs.where((d) {
                  final m = d.data();
                  final topic = (m['topic'] ?? '').toString().toLowerCase();
                  if (_search.isEmpty) return true;
                  return topic.contains(_search);
                }).toList();

                docs.sort((a, b) {
                  final da = _toDt(a.data()['createdAt']);
                  final db = _toDt(b.data()['createdAt']);

                  if (da == null && db == null) return 0;
                  if (da == null) return 1;
                  if (db == null) return -1;
                  return db.compareTo(da);
                });

                if (docs.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Card(
                        elevation: 0,
                        color: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.library_music_outlined,
                                size: 42,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                strings.noLecturesYet,
                                textAlign: TextAlign.center,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final d = docs[i];
                    final m = d.data();

                    final topic = (m['topic'] ?? '').toString();
                    final levelName = (m['levelName'] ?? '').toString();
                    final semesterName = (m['semesterName'] ?? '').toString();
                    final status = (m['transcriptStatus'] ?? 'none').toString();
                    final durationSeconds = m['durationSeconds'];

                    final dt = _toDt(m['createdAt']);

                    final subtitleParts = <String>[];
                    if (levelName.isNotEmpty) subtitleParts.add(levelName);
                    if (semesterName.isNotEmpty) subtitleParts.add(semesterName);
                    if (dt != null) subtitleParts.add(dt.toLocal().toString());
                    if (durationSeconds is num && durationSeconds > 0) {
                      subtitleParts.add(
                        formatDuration(Duration(seconds: durationSeconds.round())),
                      );
                    }
                    subtitleParts.add('${strings.transcript}: $status');

                    return Card(
                      elevation: 0,
                      color: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        leading: Icon(
                          Icons.library_music_outlined,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        title: Text(
                          topic.isEmpty ? strings.lectureTopic : topic,
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
                              builder: (_) => LectureDetailScreen(sessionId: d.id),
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
