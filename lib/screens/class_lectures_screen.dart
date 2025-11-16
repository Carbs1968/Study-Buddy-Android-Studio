// --------------------------------------
// Class Lectures (drilldown per class)
// --------------------------------------
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../l10n/strings.dart';
import 'lecture_detail_screen.dart';

class ClassLecturesScreen extends StatefulWidget {
  final String className;
  const ClassLecturesScreen({super.key, required this.className});

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
    if (uid == null) {
      return Scaffold(body: Center(child: Text(SBStrings.of(context).notSignedIn)));
    }

    // Filter at source: only this class + this user
    final q = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('recordings')
        .where('className', isEqualTo: widget.className);

    final strings = SBStrings.of(context);
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
            child: StreamBuilder<QuerySnapshot>(
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

                // Filter by topic (safe reads)
                docs = docs.where((d) {
                  final m = (d.data() as Map<String, dynamic>?) ?? const {};
                  final top = (m['topic'] ?? '').toString().toLowerCase();
                  if (_search.isEmpty) return true;
                  return top.contains(_search);
                }).toList();

                // Sort newest first
                docs.sort((a, b) {
                  final ma = (a.data() as Map<String, dynamic>?) ?? const {};
                  final mb = (b.data() as Map<String, dynamic>?) ?? const {};
                  final da = _toDt(ma['createdAt']);
                  final db = _toDt(mb['createdAt']);
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
                    final m = (d.data() as Map<String, dynamic>?) ?? const {};
                    final title =
                        '${(m['className'] ?? '').toString()} — ${(m['topic'] ?? '').toString()}';

                    final created = m['createdAt'];
                    final dt = created is String
                        ? DateTime.tryParse(created)
                        : (created is Timestamp ? created.toDate() : null);

                    final status = (m['transcriptStatus'] ?? 'none').toString();

                    return ListTile(
                      leading: const Icon(Icons.audiotrack),
                      title: Text(title,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(
                        '${dt != null ? dt.toLocal().toString() : ''} • ${strings.transcript}: $status',
                      ),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) =>
                              LectureDetailScreen(recordingId: d.id),
                        ));
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