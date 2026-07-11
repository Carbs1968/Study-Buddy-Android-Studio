// --------------------
// Settings (Additive)
// --------------------

// (imports moved to top-level; removed duplicate local imports)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
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
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(strings.settings),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 96),
          children: [
            if (user != null) ...[
              Card(
                elevation: 0,
                color: theme.cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 34,
                        backgroundImage: user.photoURL != null
                            ? NetworkImage(user.photoURL!)
                            : null,
                        child: user.photoURL == null
                            ? const Icon(Icons.person, size: 34)
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.displayName ?? strings.unknownUser,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Card(
              elevation: 0,
              color: theme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Row(
                  children: [
                    Text(
                      '${strings.language}:',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButton<Locale>(
                        value: appLocale.value,
                        isExpanded: true,
                        underline: const SizedBox.shrink(),
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
              ),
            ),
            const SizedBox(height: 12),
            if (user != null) ...[
              StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .collection('academicSettings')
                    .doc('current')
                    .snapshots(),
                builder: (context, snapshot) {
                  final data = snapshot.data?.data();
                  final academicYear =
                      (data?['levelName'] ?? 'Not set').toString();
                  final semester =
                      (data?['semesterName'] ?? 'Not set').toString();

                  return Card(
                    elevation: 0,
                    color: theme.cardColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.school_outlined,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Text(
                                'Current Academic Period',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Academic year',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            academicYear,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Semester',
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            semester,
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),
            ],
            Card(
              elevation: 0,
              color: theme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: ListTile(
                leading: Icon(
                  Icons.edit_calendar_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  'Manage Academic Settings',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                subtitle: const Text(
                  'Update the academic year and semester used for new recordings.',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AcademicSettingsScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () async {
                try {
                  // Sign out from Firebase Auth
                  await FirebaseAuth.instance.signOut();

                  // Also clear cached GoogleSignIn session
                  final gsi = GoogleSignIn(scopes: ['email']);
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