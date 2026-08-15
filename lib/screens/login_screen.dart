import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:url_launcher/url_launcher.dart';

import '../l10n/app_localizations.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static final Uri _termsUri = Uri.parse('https://studybuddynote.com/terms');
  static final Uri _privacyPolicyUri =
      Uri.parse('https://studybuddynote.com/privacy');

  Future<void> _openExternalUrl(Uri uri) async {
    final opened = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
    );

    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppLocalizations.of(context).unableToOpenPage),
        ),
      );
    }
  }

  bool _loading = false;
  String? _error;

  Future<void> _signInWithGoogle() async {
    final languageCode = Localizations.localeOf(context).languageCode;

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final gsi = GoogleSignIn(scopes: ['email']);

      // Prefer silent sign-in first (handles "already signed in" after logout)
      GoogleSignInAccount? acc = await gsi.signInSilently();
      acc ??= await gsi.signIn();

      if (acc == null) {
        if (mounted) {
          setState(() {
            _error = AppLocalizations.of(context).signInCanceled;
          });
        }
        return;
      }

      final auth = await acc.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      final user = FirebaseAuth.instance.currentUser;
      await _createUserIfNeeded(user, languageCode);
    } catch (error, stackTrace) {
      debugPrint('Google sign-in failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        setState(() {
          _error = AppLocalizations.of(context).signInFailed;
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _createUserIfNeeded(
    User? u,
    String languageCode,
  ) async {
    if (u == null) return;

    final ref = FirebaseFirestore.instance.collection('users').doc(u.uid);
    final email = u.email?.trim();
    final emailLower = email?.toLowerCase();

    await ref.set({
      'uid': u.uid,
      'email': email,
      'emailLower': emailLower,
      'displayName': u.displayName,
      'photoURL': u.photoURL,
      'provider': 'google',
      'providers': FieldValue.arrayUnion(['google']),
      'locale': languageCode, // Save resolved app language
      'updatedAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    if (emailLower != null && emailLower.isNotEmpty) {
      try {
        await FirebaseFirestore.instance
            .collection('userEmailLookup')
            .doc(emailLower)
            .set({
          'uid': u.uid,
          'email': email,
          'emailLower': emailLower,
          'displayName': u.displayName,
          'providers': FieldValue.arrayUnion(['google']),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('User email lookup write failed: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: 420,
                    minHeight: constraints.maxHeight - 56,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        const Spacer(),
                        Container(
                          width: 86,
                          height: 86,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: const [
                              BoxShadow(
                                blurRadius: 18,
                                offset: Offset(0, 8),
                                color: Color(0x332D1B69),
                              ),
                            ],
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: Image.asset(
                            'assets/icons/study_buddy_logo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          strings.appTitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineLarge?.copyWith(
                            fontSize: 34,
                            fontWeight: FontWeight.w800,
                            color: colors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          strings.loginTagline,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontSize: 17,
                            height: 1.35,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: 40),
                        if (_error != null)
                          Container(
                            width: double.infinity,
                            margin: const EdgeInsets.only(bottom: 14),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colors.errorContainer,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colors.onErrorContainer,
                              ),
                            ),
                          ),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _signInWithGoogle,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isDark
                                  ? colors.surfaceContainerHighest
                                  : Colors.white,
                              foregroundColor: colors.onSurface,
                              elevation: 3,
                              shadowColor: isDark
                                  ? Colors.black54
                                  : const Color(0x22000000),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                                side: BorderSide(
                                  color: colors.outlineVariant,
                                ),
                              ),
                            ),
                            child: _loading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Text(
                                        'G',
                                        style: TextStyle(
                                          color: Color(0xFF4285F4),
                                          fontSize: 22,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Text(
                                        strings.signInWithGoogle,
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        ),
                        const Spacer(),
                        Wrap(
                          alignment: WrapAlignment.center,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text(
                              strings.legalAgreementPrefix,
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                            TextButton(
                              onPressed: () => _openExternalUrl(_termsUri),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                strings.termsAndConditions,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            Text(
                              strings.legalAgreementMiddle,
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                            TextButton(
                              onPressed: () =>
                                  _openExternalUrl(_privacyPolicyUri),
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                strings.privacyPolicy,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            Text(
                              '.',
                              style: TextStyle(
                                color: colors.onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
