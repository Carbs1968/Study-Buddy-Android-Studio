// ---------------------------
// Library & Detail (Additive)
// ---------------------------

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
    if (uid == null) {
      return Scaffold(body: Center(child: Text(SBStrings.of(context).notSignedIn)));
    }

    final q = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('recordings');

    final strings = SBStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.library)),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.search),
                hintText: strings.selectClass,
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

                final docs = (snap.data?.docs ?? []);
                if (docs.isEmpty) {
                  return Center(child: Text(strings.noRecordingsYet));
                }

                // Aggregate by className
                final Map<String, _ClassRow> classes = {};
                for (final d in docs) {
                  final m = (d.data() as Map<String, dynamic>?) ?? const {};
                  final className = (m['className'] ?? '').toString().trim();
                  if (className.isEmpty) continue;

                  final createdAt = _toDt(m['createdAt']);
                  final row =
                  classes.putIfAbsent(className, () => _ClassRow(className));
                  row.count += 1;
                  if (createdAt != null &&
                      (row.latest == null || createdAt.isAfter(row.latest!))) {
                    row.latest = createdAt;
                  }
                }

                // Filter by class search
                var items = classes.values
                    .where((r) =>
                _search.isEmpty ||
                    r.className.toLowerCase().contains(_search))
                    .toList();

                // Sort by latest desc, then name
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
                  return Center(child: Text(strings.noClassesMatch));
                }

                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final r = items[i];
                    final subtitle = [
                      if (r.latest != null) r.latest!.toLocal().toString(),
                      strings.lectureCount(r.count),
                    ].join(' • ');
                    return ListTile(
                      leading: const Icon(Icons.folder),
                      title: Text(r.className,
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      subtitle: Text(subtitle),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) =>
                              ClassLecturesScreen(className: r.className),
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

class _ClassRow {
  final String className;
  int count = 0;
  DateTime? latest;
  _ClassRow(this.className);
}