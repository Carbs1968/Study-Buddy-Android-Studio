// lib/main.dart

// --------------------
// Dart imports
// --------------------
import 'dart:async';

// --------------------
// Flutter imports
// --------------------
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

// --------------------
// Third-party and Firebase imports
// --------------------
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart'; // ✅ NEW
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:study_buddy/utils/utils.dart';

// --------------------
// Local project imports
// --------------------
import 'firebase_options.dart';
import 'l10n/app_localizations.dart';
// Added import for AcademicSettingsScreen at top-level to avoid misplaced directives.
import 'screens/home_shell/home_shell.dart';
import 'screens/login_screen.dart';
import 'screens/onboarding/onboarding_screen.dart';
import 'screens/academic_settings_screen.dart';
import 'utils/app_logger.dart';
import 'utils/constants.dart';

final ValueNotifier<Locale?> appLocale = ValueNotifier(null);

// // ✅ Single Functions handle (same app-wide region as your backend)
// late FirebaseFunctions functions;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

// Initialize Firebase first.
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    appLogger('Firebase.initializeApp succeeded.');
  } catch (e) {
    appLogger('Firebase init failed: $e');
  }

// Activate App Check.  Use the debug provider in non‑release builds so App Check doesn’t block your backend calls.
  appLogger('Preparing to activate App Check...');
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider:
          kReleaseMode ? AndroidProvider.playIntegrity : AndroidProvider.debug,
      appleProvider:
          kReleaseMode ? AppleProvider.appAttest : AppleProvider.debug,
    );
    appLogger(
        'AppCheck activated with ${kReleaseMode ? 'production' : 'debug'} providers');
  } catch (e) {
    appLogger('AppCheck activation skipped/failed: $e');
  }
  appLogger('App Check activation complete.');

  appLogger('Using Storage bucket: ${FirebaseStorage.instance.bucket}');

  // Initialize global FirebaseFunctions handle after Firebase is ready
  functions = FirebaseFunctions.instanceFor(region: 'us-central1');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<Locale?>(
      valueListenable: appLocale,
      builder: (context, locale, _) {
        return MaterialApp(
          onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: kBrandPrimary,
              brightness: Brightness.light,
            ),
            scaffoldBackgroundColor: kBrandSurface,
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.black87,
              elevation: 0,
              titleTextStyle: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 22,
                color: Colors.black87,
              ),
            ),
            bottomNavigationBarTheme: BottomNavigationBarThemeData(
              selectedItemColor: kBrandPrimary,
              unselectedItemColor: Colors.black54,
              backgroundColor: kBrandSurface,
              type: BottomNavigationBarType.fixed,
            ),
            inputDecorationTheme: const InputDecorationTheme(
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(width: 2),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: kBrandPrimary,
                foregroundColor: Colors.white,
                shape: const StadiumBorder(),
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                textStyle:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: kBrandPrimary,
                textStyle: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            textTheme: const TextTheme(
              headlineLarge: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87),
              headlineMedium: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87),
              headlineSmall: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87),
              titleLarge: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87),
              bodyLarge:
                  TextStyle(fontSize: 16, color: Colors.black87, height: 1.4),
              bodyMedium:
                  TextStyle(fontSize: 14, color: Colors.black87, height: 1.4),
              labelLarge: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
              labelMedium: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.black87),
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(
              seedColor: kBrandPrimary,
              brightness: Brightness.dark,
            ),
            scaffoldBackgroundColor: const Color(0xFF12131A),
            cardTheme: const CardThemeData(
              color: Color(0xFF1B1D27),
              elevation: 0,
            ),
            appBarTheme: const AppBarTheme(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              elevation: 0,
              titleTextStyle: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 22,
                color: Colors.white,
              ),
            ),
            bottomNavigationBarTheme: const BottomNavigationBarThemeData(
              selectedItemColor: kBrandAccent,
              unselectedItemColor: Colors.white70,
              backgroundColor: Color(0xFF181A22),
              type: BottomNavigationBarType.fixed,
            ),
            inputDecorationTheme: const InputDecorationTheme(
              filled: true,
              fillColor: Color(0xFF1B1D27),
              border: OutlineInputBorder(),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(width: 2, color: kBrandAccent),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: kBrandAccent,
                foregroundColor: Colors.black87,
                shape: const StadiumBorder(),
                padding:
                    const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
                textStyle:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: kBrandAccent,
                textStyle: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            textTheme: const TextTheme(
              headlineLarge: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
              headlineMedium: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.white),
              headlineSmall: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
              titleLarge: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white),
              bodyLarge:
                  TextStyle(fontSize: 16, color: Colors.white70, height: 1.4),
              bodyMedium:
                  TextStyle(fontSize: 14, color: Colors.white70, height: 1.4),
              labelLarge: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87),
              labelMedium: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.white),
            ),
          ),
          themeMode: ThemeMode.system,
          home: const AuthGate(),
          debugShowCheckedModeBanner: false,
          locale: locale,
          supportedLocales: AppLocalizations.supportedLocales,
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        );
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<fb.User?>(
      stream: fb.FirebaseAuth.instance.authStateChanges(),
      builder: (context, authSnapshot) {
        if (authSnapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = authSnapshot.data;
        if (user == null) {
          return const LoginScreen();
        }

        final settingsDocument = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('academicSettings')
            .doc('current');

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: settingsDocument.snapshots(),
          builder: (context, settingsSnapshot) {
            if (settingsSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (settingsSnapshot.hasError) {
              return const Scaffold(
                body: Center(
                  child: Text('Unable to load academic settings.'),
                ),
              );
            }

            final hasAcademicSettings = settingsSnapshot.data?.exists ?? false;

            if (!hasAcademicSettings) {
              return OnboardingScreen(
                onComplete: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const AcademicSettingsScreen(),
                    ),
                  );
                },
              );
            }

            // RecorderPage remains the first HomeShell tab.
            return const HomeShell();
          },
        );
      },
    );
  }
}
