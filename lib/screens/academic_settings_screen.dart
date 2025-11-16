import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../l10n/strings.dart';

class AcademicSettingsScreen extends StatefulWidget {
  const AcademicSettingsScreen({super.key});

  @override
  State<AcademicSettingsScreen> createState() => _AcademicSettingsScreenState();
}

class _AcademicSettingsScreenState extends State<AcademicSettingsScreen> {
  final _levels = ['High School', 'Undergraduate', 'Graduate', 'Doctorate'];
  final _terms = ['Spring', 'Summer', 'Fall', 'Winter'];

  String? _selectedLevel;
  String? _selectedTerm;
  bool _saving = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = fb.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('academicSettings')
        .doc('current');

    final doc = await docRef.get();

    if (doc.exists) {
      final data = doc.data()!;
      String? level = data['levelName'];
      String? term = data['termName'];

      bool invalid = false;

      // Check validity for level
      if (level != null && _levels.contains(level)) {
        _selectedLevel = level;
      } else {
        invalid = true;
        _selectedLevel = null; // do NOT select invalid value
      }

      // Check validity for term
      if (term != null && _terms.contains(term)) {
        _selectedTerm = term;
      } else {
        invalid = true;
        _selectedTerm = null; // do NOT select invalid value
      }

      if (invalid && mounted) {
        // Show alert/snackbar for incorrect academic values
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Your saved academic values are incorrect. Please re-select.',
              ),
            ),
          );
        });
      }
    }

    setState(() => _loading = false);
  }

  Future<void> _saveSettings() async {
    final user = fb.FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_selectedLevel == null || _selectedTerm == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both Level and Term.')),
      );
      return;
    }

    setState(() => _saving = true);

    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('academicSettings')
        .doc('current');

    await docRef.set({
      'levelName': _selectedLevel,
      'termName': _selectedTerm,
      'isActive': true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    setState(() => _saving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Academic settings saved successfully.')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final strings = SBStrings.of(context);
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
              strings.selectAcademicLevel,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedLevel,
              items: _levels
                  .map((level) => DropdownMenuItem(
                value: level,
                child: Text(level),
              ))
                  .toList(),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Select Level',
              ),
              onChanged: (val) => setState(() => _selectedLevel = val),
            ),
            const SizedBox(height: 24),
            Text(
              strings.selectTerm,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _selectedTerm,
              items: _terms
                  .map((term) => DropdownMenuItem(
                value: term,
                child: Text(term),
              ))
                  .toList(),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Select Term',
              ),
              onChanged: (val) => setState(() => _selectedTerm = val),
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