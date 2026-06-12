import 'package:flutter/material.dart';

import '../design/design_tokens.dart';
import '../design/typography.dart';

/// Standard dialog shell: title row with close, scrollable body, action bar.
/// Screens pass their form fields as [children] and buttons as [actions].
class AppDialog extends StatelessWidget {
  const AppDialog({
    super.key,
    required this.title,
    required this.children,
    required this.actions,
    this.maxWidth = 480,
  });

  final String title;
  final List<Widget> children;
  final List<Widget> actions;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: DS.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(DS.rXl)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(DS.s24, DS.s20, DS.s12, DS.s8),
              child: Row(
                children: [
                  Expanded(child: Text(title, style: AppType.h2)),
                  IconButton(
                    icon: const Icon(Icons.close, color: DS.muted, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: DS.line),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                    DS.s24, DS.s20, DS.s24, DS.s8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: children,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                  DS.s24, DS.s12, DS.s24, DS.s20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  for (var i = 0; i < actions.length; i++) ...[
                    if (i > 0) const SizedBox(width: DS.s12),
                    actions[i],
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A labelled form field wrapper for use inside AppDialog.
class DialogField extends StatelessWidget {
  const DialogField({super.key, required this.label, required this.child});
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DS.s16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppType.small.copyWith(
              color: DS.inkSoft, fontWeight: FontWeight.w600)),
          const SizedBox(height: DS.s6),
          child,
        ],
      ),
    );
  }
}
