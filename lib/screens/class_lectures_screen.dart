import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import 'lecture_detail_screen.dart';

class ClassLecturesScreen extends StatefulWidget {
  final String className;
  final String academicYearId;
  final String semesterId;
  final String classId;

  const ClassLecturesScreen({
    super.key,
    required this.className,
    this.academicYearId = '',
    this.semesterId = '',
    this.classId = '',
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

    final q = hasStableClassContext
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
      appBar: AppBar(title: Text(widget.className)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: '${strings.lectureTopic}...',
                border: const OutlineInputBorder(),
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
                  return Center(child: Text(strings.noLecturesYet));
                }

                return ListView.separated(
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final d = docs[i];
                    final m = d.data();

                    final className = (m['className'] ?? '').toString();
                    final topic = (m['topic'] ?? '').toString();
                    final levelName = (m['levelName'] ?? '').toString();
                    final semesterName = (m['semesterName'] ?? '').toString();
                    final status = (m['transcriptStatus'] ?? 'none').toString();

                    final dt = _toDt(m['createdAt']);

                    final subtitleParts = <String>[];
                    if (levelName.isNotEmpty) subtitleParts.add(levelName);
                    if (semesterName.isNotEmpty) subtitleParts.add(semesterName);
                    if (dt != null) subtitleParts.add(dt.toLocal().toString());
                    subtitleParts.add('${strings.transcript}: $status');

                    return ListTile(
                      leading: const Icon(Icons.library_music),
                      title: Text(
                        '$className — $topic',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
