// --------------------
// Settings (Additive)
// --------------------

// (imports moved to top-level; removed duplicate local imports)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../l10n/strings.dart';
import '../../../main.dart';
import '../../academic_settings_screen.dart';
import '../../login_screen.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  static final Uri _privacyPolicyUri =
      Uri.parse('https://studybuddynote.com/privacy');
  static final Uri _termsUri = Uri.parse('https://studybuddynote.com/terms');

  Future<void> _openExternalUrl(BuildContext context, Uri uri) async {
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open link. Please try again.')),
      );
    }
  }

  Future<void> _confirmAndDeleteAccount(BuildContext context) async {
    final confirmationController = TextEditingController();
    var isDeleting = false;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            final canDelete =
                confirmationController.text.trim() == 'DELETE' && !isDeleting;

            return AlertDialog(
              icon: Icon(
                Icons.warning_amber_rounded,
                color: Theme.of(context).colorScheme.error,
                size: 48,
              ),
              title: const Text(
                'Permanently delete your account?',
                textAlign: TextAlign.center,
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'This will permanently delete your Study Buddy account and all associated data, including:',
                    ),
                    const SizedBox(height: 12),
                    const Text(
                        '• Academic years, semesters, classes, and topics'),
                    const Text('• Recordings and uploaded files'),
                    const Text(
                      '• Transcripts, summaries, notes, quizzes, and study guides',
                    ),
                    const Text('• Account and profile information'),
                    const SizedBox(height: 16),
                    Text(
                      'This action cannot be undone.',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('To continue, type DELETE below:'),
                    const SizedBox(height: 8),
                    TextField(
                      controller: confirmationController,
                      enabled: !isDeleting,
                      autofocus: true,
                      autocorrect: false,
                      enableSuggestions: false,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'DELETE',
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: isDeleting
                      ? null
                      : () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.error,
                    foregroundColor: Theme.of(context).colorScheme.onError,
                  ),
                  onPressed: canDelete
                      ? () {
                          setState(() {
                            isDeleting = true;
                          });
                          Navigator.of(dialogContext).pop(true);
                        }
                      : null,
                  child: const Text('Delete My Account Permanently'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final messenger = ScaffoldMessenger.of(context);

    try {
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Deleting your account and data…'),
          duration: Duration(seconds: 30),
        ),
      );

      final callable =
          FirebaseFunctions.instance.httpsCallable('deleteMyAccount');
      await callable.call();

      try {
        await FirebaseAuth.instance.signOut();
      } catch (_) {}

      try {
        final googleSignIn = GoogleSignIn(scopes: ['email']);
        await googleSignIn.signOut();
      } catch (_) {}

      if (!context.mounted) {
        return;
      }

      messenger.hideCurrentSnackBar();
    } on FirebaseFunctionsException catch (error) {
      if (!context.mounted) {
        return;
      }

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            error.message ??
                'We could not delete your account. Please try again.',
          ),
        ),
      );
    } catch (_) {
      if (!context.mounted) {
        return;
      }

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'We could not delete your account. Please try again.',
          ),
        ),
      );
    }
  }

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
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.email ?? '',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
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
                padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
                child: Row(
                  children: [
                    Icon(
                      Icons.language_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            strings.language,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Choose the app language.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    DropdownButton<Locale>(
                      value: appLocale.value,
                      underline: const SizedBox.shrink(),
                      items: SBStrings.supportedLocales
                          .map((l) => DropdownMenuItem(
                                value: l,
                                child: Text(
                                  SBStrings.localeNames[l.languageCode] ??
                                      l.languageCode,
                                ),
                              ))
                          .toList(),
                      onChanged: (val) async {
                        if (val == null) return;
                        appLocale.value = val;
                        final u = FirebaseAuth.instance.currentUser;
                        if (u != null) {
                          await FirebaseFirestore.instance
                              .collection('users')
                              .doc(u.uid)
                              .set(
                            {'locale': val.languageCode},
                            SetOptions(merge: true),
                          );
                        }
                      },
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
                    MaterialPageRoute(
                        builder: (_) => const AcademicSettingsScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 0,
              color: theme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(
                      Icons.privacy_tip_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(
                      'Privacy Policy',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () => _openExternalUrl(context, _privacyPolicyUri),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      Icons.description_outlined,
                      color: theme.colorScheme.primary,
                    ),
                    title: Text(
                      'Terms and Conditions',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    trailing: const Icon(Icons.open_in_new),
                    onTap: () => _openExternalUrl(context, _termsUri),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: Icon(
                      Icons.delete_forever_outlined,
                      color: theme.colorScheme.error,
                    ),
                    title: Text(
                      'Delete Account',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: theme.colorScheme.error,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: const Text(
                      'Permanently delete your account and all associated data.',
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: theme.colorScheme.error,
                    ),
                    onTap: () => _confirmAndDeleteAccount(context),
                  ),
                ],
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
                    try {
                      await gsi.signOut();
                    } catch (_) {}
                    try {
                      await gsi.disconnect();
                    } catch (_) {}
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
