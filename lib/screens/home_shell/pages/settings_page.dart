// --------------------
// Settings (Additive)
// --------------------

// (imports moved to top-level; removed duplicate local imports)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';

import '../../../l10n/strings.dart';
import '../../../main.dart';
import '../../academic_settings_screen.dart';
import '../../login_screen.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    final strings = SBStrings.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(strings.settings)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (user != null) ...[
              CircleAvatar(
                radius: 50,
                backgroundImage:
                user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                child: user.photoURL == null
                    ? const Icon(Icons.person, size: 50)
                    : null,
              ),
              const SizedBox(height: 12),
              Text(
                user.displayName ?? strings.unknownUser,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                user.email ?? '',
                style: const TextStyle(color: Colors.black54),
              ),
              const Divider(height: 40),
            ],
            // Language picker
            Row(
              children: [
                Text('${strings.language}:', style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButton<Locale>(
                    value: appLocale.value,
                    isExpanded: true,
                    items: SBStrings.supportedLocales
                        .map((l) => DropdownMenuItem(
                      value: l,
                      child: Text(SBStrings.localeNames[l.languageCode] ?? l.languageCode),
                    ))
                        .toList(),
                    onChanged: (val) async {
                      if (val == null) return;
                      appLocale.value = val;
                      final u = FirebaseAuth.instance.currentUser;
                      if (u != null) {
                        await FirebaseFirestore.instance.collection('users').doc(u.uid).set(
                          {'locale': val.languageCode},
                          SetOptions(merge: true),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              title: Text(strings.autoTranscribeAfterUpload),
              value: false,
              onChanged: (v) {},
            ),
            SwitchListTile(
              title: Text(strings.autoGenerateNotes),
              value: false,
              onChanged: (v) {},
            ),
            // Insert Academic Settings button here
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AcademicSettingsScreen()),
                );
              },
              child: Text(SBStrings.of(context).academicSettingsTitle),
            ),
            const Spacer(),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  // Sign out from Firebase Auth
                  await FirebaseAuth.instance.signOut();

                  // Also clear cached GoogleSignIn session
                  final gsi = GoogleSignIn(scopes: [drive.DriveApi.driveFileScope, 'email']);
                  GoogleSignInAccount? acc = await gsi.signInSilently();
                  if (acc != null) {
                    try { await gsi.signOut(); } catch (_) {}
                    try { await gsi.disconnect(); } catch (_) {}
                  }

                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (_) => false,
                    );
                  }
                } catch (_) {
                  if (context.mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const LoginScreen()),
                          (_) => false,
                    );
                  }
                }
              },
              icon: const Icon(Icons.logout),
              label: Text(strings.logout),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}