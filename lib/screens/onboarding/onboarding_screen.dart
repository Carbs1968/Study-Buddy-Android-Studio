import 'package:flutter/material.dart';

import '../../l10n/app_localizations.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({
    super.key,
    required this.onComplete,
  });

  final VoidCallback onComplete;

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const int _pageCount = 4;

  List<_OnboardingPageData> _pages(AppLocalizations l10n) {
    return [
      _OnboardingPageData(
        title: l10n.onboardingWelcomeTitle,
        description: l10n.onboardingWelcomeDescription,
        imageAsset: 'assets/images/onboarding_hero_en.png',
      ),
      _OnboardingPageData(
        title: l10n.onboardingCaptureTitle,
        description: l10n.onboardingCaptureDescription,
        icon: Icons.auto_awesome_rounded,
      ),
      _OnboardingPageData(
        title: l10n.onboardingOrganizeTitle,
        description: l10n.onboardingOrganizeDescription,
        icon: Icons.account_tree_rounded,
      ),
      _OnboardingPageData(
        title: l10n.onboardingSetupTitle,
        description: l10n.onboardingSetupDescription,
        icon: Icons.school_rounded,
      ),
    ];
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _goForward() async {
    if (_currentPage == _pageCount - 1) {
      widget.onComplete();
      return;
    }

    await _pageController.nextPage(
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _skip() async {
    await _pageController.animateToPage(
      _pageCount - 1,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final pages = _pages(l10n);
    final isLastPage = _currentPage == _pageCount - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, right: 12),
                child: TextButton(
                  onPressed: isLastPage ? null : _skip,
                  child: Text(l10n.onboardingSkip),
                ),
              ),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _pageCount,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  return _OnboardingPage(data: pages[index]);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(
                      _pageCount,
                      (index) => AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        width: index == _currentPage ? 24 : 8,
                        height: 8,
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        decoration: BoxDecoration(
                          color: index == _currentPage
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _goForward,
                      child: Text(isLastPage
                          ? l10n.onboardingSetupButton
                          : l10n.onboardingContinue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.data});

  final _OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.sizeOf(context);
    final visualHeight = (size.height * 0.34).clamp(220.0, 340.0);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: size.height * 0.62),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              height: visualHeight,
              width: double.infinity,
              child: data.imageAsset != null
                  ? Image.asset(
                      data.imageAsset!,
                      fit: BoxFit.contain,
                      semanticLabel: 'Student using Study Buddy',
                    )
                  : Center(
                      child: Container(
                        width: 152,
                        height: 152,
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primaryContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          data.icon,
                          size: 76,
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
            ),
            const SizedBox(height: 24),
            Text(
              data.title,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Text(
                data.description,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.title,
    required this.description,
    this.imageAsset,
    this.icon,
  });

  final String title;
  final String description;
  final String? imageAsset;
  final IconData? icon;
}
