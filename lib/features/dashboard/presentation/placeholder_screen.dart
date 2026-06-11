import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';

/// Generic placeholder for features whose UI/logic arrives in later phases.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.tableNote,
  });

  final String title;
  final IconData icon;

  /// Reminds which existing table this feature is built around.
  final String tableNote;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title.toUpperCase(),
              style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Text(title, style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 24),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.line),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 40, color: AppColors.muted),
                    const SizedBox(height: 14),
                    Text('$title module',
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text(tableNote,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
