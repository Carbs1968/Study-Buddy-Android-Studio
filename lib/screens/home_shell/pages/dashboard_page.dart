import 'package:flutter/material.dart';

import '../../../l10n/strings.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = SBStrings.of(context);
    final theme = Theme.of(context);

    return SafeArea(
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
        children: [
          Text(
            strings.appTitle,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Organize your recordings and study materials by class and topic.',
            style: theme.textTheme.bodyLarge,
          ),
          const SizedBox(height: 24),
          _DashboardActionCard(
            icon: Icons.mic_none,
            title: strings.record,
            subtitle: 'Start a new classroom recording.',
          ),
          const SizedBox(height: 12),
          const _DashboardActionCard(
            icon: Icons.upload_file_outlined,
            title: 'Upload Study Material',
            subtitle: 'Add PDFs, documents, or other class materials.',
          ),
          const SizedBox(height: 24),
          Text(
            'Classes',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your academic dashboard will show classes, topics, recordings, and uploads here.',
          ),
        ],
      ),
    );
  }
}

class _DashboardActionCard extends StatelessWidget {
  const _DashboardActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: ListTile(
        leading: Icon(icon),
        title: Text(
          title,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(subtitle),
      ),
    );
  }
}
