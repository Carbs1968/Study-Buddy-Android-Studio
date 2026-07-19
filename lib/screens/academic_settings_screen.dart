import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;

import '../l10n/app_localizations.dart';
import '../utils/app_logger.dart';

class AcademicSettingsScreen extends StatefulWidget {
  const AcademicSettingsScreen({super.key});

  @override
  State<AcademicSettingsScreen> createState() => _AcademicSettingsScreenState();
}

class _AcademicSettingsScreenState extends State<AcademicSettingsScreen> {
  final TextEditingController _levelCtl = TextEditingController();
  final TextEditingController _semesterCtl = TextEditingController();

  bool _saving = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    _levelCtl.dispose();
    _semesterCtl.dispose();
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final user = fb.FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('academicSettings')
          .doc('current');

      final doc = await docRef.get();

      if (doc.exists) {
        final data = doc.data()!;
        _levelCtl.text = (data['levelName'] ?? '').toString();
        _semesterCtl.text = (data['semesterName'] ?? data['termName'] ?? '').toString();
      }
    } catch (e) {
      appLogger('Academic settings load failed: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              AppLocalizations.of(context).academicSettingsLoadFailed,
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _saveSettings() async {
    final user = fb.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final levelName = _levelCtl.text.trim();
    final semesterName = _semesterCtl.text.trim();

    if (levelName.isEmpty || semesterName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).academicSettingsRequired),
        ),
      );
      return;
    }

    setState(() => _saving = true);

    try {
      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('academicSettings')
          .doc('current');

      await docRef.set({
        'levelName': levelName,
        'semesterName': semesterName,
        'isActive': true,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).academicSettingsSaved),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      appLogger('Academic settings save failed: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppLocalizations.of(context).academicSettingsSaveFailed,
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(strings.academicSettingsTitle),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              strings.academicLevelYear,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _levelCtl,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: strings.academicLevelYearHint,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              strings.academicLevelYearHelp,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              strings.currentSemesterTerm,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _semesterCtl,
              textInputAction: TextInputAction.done,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                hintText: strings.currentSemesterTermHint,
              ),
              onSubmitted: (_) {
                if (!_saving) _saveSettings();
              },
            ),
            const SizedBox(height: 8),
            Text(
              strings.currentSemesterTermHelp,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _saving ? null : _saveSettings,
                icon: _saving
                    ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
                    : const Icon(Icons.save),
                label: Text(
                  _saving ? strings.saving : strings.saveChanges,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}