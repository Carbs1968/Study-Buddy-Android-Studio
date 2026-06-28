import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../l10n/strings.dart';
import '../main.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _loading = false;
  String? _error;

  Future<void> _signInWithGoogle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final gsi = GoogleSignIn(scopes: ['email']);

      // Prefer silent sign-in first (handles "already signed in" after logout)
      GoogleSignInAccount? acc = await gsi.signInSilently();
      acc ??= await gsi.signIn();
      if (acc == null) throw 'Sign-in canceled';

      final auth = await acc.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: auth.accessToken,
        idToken: auth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      final user = FirebaseAuth.instance.currentUser;
      await _createUserIfNeeded(user);
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createUserIfNeeded(User? u) async {
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
      'locale': appLocale.value.languageCode, // Save user's language
      'updatedAt': FieldValue.serverTimestamp(),
      'lastLoginAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    final strings = SBStrings.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F4FC),
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
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF1F2937),
                        ),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Record and organize your classes.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 17,
                          height: 1.35,
                          color: Color(0xFF667085),
                        ),
                      ),
                      const SizedBox(height: 40),
                      if (_error != null)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(bottom: 14),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFEBEE),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Color(0xFFC62828)),
                          ),
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _loading ? null : _signInWithGoogle,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF1F2937),
                            elevation: 3,
                            shadowColor: const Color(0x22000000),
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                              side: const BorderSide(color: Color(0xFFE5E7EB)),
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
                        const Text(
                          'By continuing, you agree to our Terms and Privacy Policy.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF98A2B3),
                            fontSize: 13,
                          ),
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