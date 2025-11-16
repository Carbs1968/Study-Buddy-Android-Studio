// ----------------------------
// Bottom-Nav Shell (Additive)
// ----------------------------
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../l10n/strings.dart';
import '../../main.dart';
import 'pages/library_page.dart';
import 'pages/recorder_page.dart';
import 'pages/settings_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});
  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _tab = 0;
  final _tabs = const [
    RecorderPage(),
    LibraryPage(),
    SettingsPage(),
  ];

  @override
  void initState() {
    super.initState();
    _loadSavedLocale();
  }

  Future<void> _loadSavedLocale() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    try {
      final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
      final data = doc.data();
      if (data != null && data['locale'] != null) {
        final code = data['locale'] as String;
        if (SBStrings.supportedLocales.any((l) => l.languageCode == code)) {
          appLocale.value = Locale(code);
        }
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final strings = SBStrings.of(context);
    return Scaffold(
      body: _tabs[_tab],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _tab,
        onTap: (i) => setState(() => _tab = i),
        items: [
          BottomNavigationBarItem(icon: const Icon(Icons.mic), label: strings.record),
          BottomNavigationBarItem(icon: const Icon(Icons.library_music), label: strings.library),
          BottomNavigationBarItem(icon: const Icon(Icons.settings), label: strings.settings),
        ],
      ),
    );
  }
}