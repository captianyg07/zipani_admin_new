import 'package:flutter/material.dart';

import '../design/design_tokens.dart';
import '../design/typography.dart';
import 'app_button.dart';

class LoadingState extends StatelessWidget {
  const LoadingState({super.key, this.height = 280});
  final double height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: const Center(
        child: CircularProgressIndicator(color: DS.brand, strokeWidth: 2.5),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      children: [
        _IconBubble(icon: icon, color: DS.muted),
        const SizedBox(height: DS.s16),
        Text(title, style: AppType.h3),
        const SizedBox(height: DS.s6),
        Text(message, textAlign: TextAlign.center, style: AppType.small),
      ],
    );
  }
}

class ErrorState extends StatelessWidget {
  const ErrorState({
    super.key,
    required this.message,
    required this.onRetry,
    this.title = 'Something went wrong',
  });

  final String message;
  final String title;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return _Panel(
      children: [
        _IconBubble(icon: Icons.error_outline, color: DS.danger),
        const SizedBox(height: DS.s16),
        Text(title, style: AppType.h3),
        const SizedBox(height: DS.s6),
        Text(message, textAlign: TextAlign.center, style: AppType.small),
        const SizedBox(height: DS.s20),
        AppButton(label: 'Try again', onPressed: onRetry),
      ],
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: DS.s48, horizontal: DS.s24),
      decoration: BoxDecoration(
        color: DS.surface,
        borderRadius: BorderRadius.circular(DS.rLg),
        boxShadow: DS.shadowSm,
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    );
  }
}

class _IconBubble extends StatelessWidget {
  const _IconBubble({required this.icon, required this.color});
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, color: color, size: 26),
    );
  }
}
