import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:google_sign_in/google_sign_in.dart';

import '../l10n/strings.dart';
import '../main.dart';
import '../utils/constants.dart';

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
      final gsi = GoogleSignIn(scopes: [
        drive.DriveApi.driveFileScope,
        'email',
      ]);

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
    final snap = await ref.get();
    if (!snap.exists) {
      await ref.set({
        'uid': u.uid,
        'email': u.email,
        'displayName': u.displayName,
        'photoURL': u.photoURL,
        'createdAt': FieldValue.serverTimestamp(),
        'provider': 'google',
        'locale': appLocale.value.languageCode, // Save user's language
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = SBStrings.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                strings.appTitle,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: kBrandPrimary,
                ),
              ),
              const SizedBox(height: 40),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_error!, style: const TextStyle(color: Colors.red)),
                ),
              SizedBox(
                width: 300,
                child: ElevatedButton(
                  onPressed: _loading ? null : _signInWithGoogle,
                  child: _loading
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                      : Text(strings.signInWithGoogle),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}