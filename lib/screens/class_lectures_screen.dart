import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../utils/helper.dart';
import 'class_materials_screen.dart';
import 'class_study_guide_screen.dart';
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

  String _formatLectureDate(BuildContext context, DateTime dt) {
    final local = dt.toLocal();
    final material = MaterialLocalizations.of(context);
    return '${material.formatMediumDate(local)} • ${material.formatTimeOfDay(
      TimeOfDay.fromDateTime(local),
    )}';
  }

  String _formatTranscriptStatus(
    BuildContext context,
    String status,
  ) {
    final strings = AppLocalizations.of(context);

    switch (status.toLowerCase()) {
      case 'done':
        return strings.transcriptReady;
      case 'processing':
        return strings.transcriptProcessing;
      case 'pending':
        return strings.transcriptQueued;
      case 'error':
        return strings.transcriptFailed;
      case 'none':
      case '':
        return strings.noTranscript;
      default:
        return status;
    }
  }

  String _formatAiStatus(
    BuildContext context, {
    required String summaryStatus,
    required String notesStatus,
    required String quizStatus,
  }) {
    final strings = AppLocalizations.of(context);
    final statuses = [
      summaryStatus.toLowerCase(),
      notesStatus.toLowerCase(),
      quizStatus.toLowerCase(),
    ];

    if (statuses.any((status) => status == 'pending' || status == 'processing')) {
      return strings.aiProcessing;
    }

    final readyCount = statuses.where((status) => status == 'done').length;
    if (readyCount >= 2) {
      return strings.aiOutputsReady(readyCount);
    }

    if (readyCount == 1) {
      if (summaryStatus.toLowerCase() == 'done') {
        return strings.aiSummaryReady;
      }
      if (notesStatus.toLowerCase() == 'done') {
        return strings.aiNotesReady;
      }
      if (quizStatus.toLowerCase() == 'done') {
        return strings.aiQuizReady;
      }
    }

    if (statuses.any((status) => status == 'error')) {
      return strings.aiFailed;
    }

    return strings.aiNotStarted;
  }

  Future<void> _openOrRequestClassStudyGuide() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final messenger = ScaffoldMessenger.of(context);
    final classRef = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('academicYears')
        .doc(widget.academicYearId)
        .collection('semesters')
        .doc(widget.semesterId)
        .collection('classes')
        .doc(widget.classId);

    try {
      final classDoc = await classRef.get();
      final data = classDoc.data() ?? {};
      final status = (data['classStudyGuideStatus'] ?? '').toString();
      final guideId = (data['latestStudyGuideId'] ?? '').toString();

      if (!mounted) return;
      if (status == 'done' && guideId.isNotEmpty) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ClassStudyGuideScreen(
              academicYearId: widget.academicYearId,
              semesterId: widget.semesterId,
              classId: widget.classId,
              guideId: guideId,
              className: widget.className,
            ),
          ),
        );
        return;
      }

      await _requestClassStudyGuide();
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).studyGuideOpenFailed)),
      );
    }
  }

  Future<void> _requestClassStudyGuide() async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      messenger.showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).studyGuideRequesting)),
      );

      final callable =
          FirebaseFunctions.instance.httpsCallable('requestClassStudyGuide');
      final result = await callable.call<Map<String, dynamic>>({
        'academicYearId': widget.academicYearId,
        'semesterId': widget.semesterId,
        'classId': widget.classId,
      });

      final data = result.data;
      final reused = data['reused'] == true;

      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            reused
                ? AppLocalizations.of(context).studyGuideAlreadyRequested
                : AppLocalizations.of(context).studyGuideRequested,
          ),
        ),
      );
    } on FirebaseFunctionsException {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).studyGuideRequestFailed),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text(AppLocalizations.of(context).studyGuideRequestFailed)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);

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
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(widget.className),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: AppLocalizations.of(context).generateStudyGuideTooltip,
            icon: const Icon(Icons.auto_awesome_outlined),
            onPressed: hasStableClassContext ? _openOrRequestClassStudyGuide : null,
          ),
          IconButton(
            tooltip: AppLocalizations.of(context).materialsTooltip,
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
                fillColor: theme.colorScheme.surface,
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
                        strings.classLecturesLoadFailed,
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
                    final summaryStatus = (m['summaryStatus'] ?? 'none').toString();
                    final notesStatus = (m['notesStatus'] ?? 'none').toString();
                    final quizStatus = (m['quizStatus'] ?? 'none').toString();
                    final durationSeconds = m['durationSeconds'];

                    final dt = _toDt(m['createdAt']);

                    final contextParts = <String>[];
                    if (levelName.isNotEmpty) contextParts.add(levelName);
                    if (semesterName.isNotEmpty) contextParts.add(semesterName);
                    if (dt != null) contextParts.add(_formatLectureDate(context, dt));

                    final detailParts = <String>[];
                    if (durationSeconds is num && durationSeconds > 0) {
                      detailParts.add(
                        AppLocalizations.of(context).durationValue(
                          formatDuration(
                            Duration(seconds: durationSeconds.round()),
                          ),
                        ),
                      );
                    }
                    detailParts.add(_formatTranscriptStatus(context, status));

                    final aiStatus = _formatAiStatus(
                      context,
                      summaryStatus: summaryStatus,
                      notesStatus: notesStatus,
                      quizStatus: quizStatus,
                    );

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
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (contextParts.isNotEmpty)
                              Text(
                                contextParts.join(' • '),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            Text(
                              detailParts.join(' • '),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              aiStatus,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
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
