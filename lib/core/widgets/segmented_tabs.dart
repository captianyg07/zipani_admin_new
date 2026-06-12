import 'package:flutter/material.dart';

import '../design/design_tokens.dart';
import '../design/typography.dart';

class SegTab {
  const SegTab(this.label, {this.count});
  final String label;
  final int? count;
}

/// Horizontal segmented tabs (e.g. New / Preparing / Ready). Generic over the
/// caller's value type so it binds directly to existing filter state.
class SegmentedTabs<T> extends StatelessWidget {
  const SegmentedTabs({
    super.key,
    required this.values,
    required this.tabs,
    required this.selected,
    required this.onSelected,
  });

  final List<T> values;
  final List<SegTab> tabs;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var i = 0; i < values.length; i++)
            Padding(
              padding: const EdgeInsets.only(right: DS.s8),
              child: _Tab(
                tab: tabs[i],
                active: values[i] == selected,
                onTap: () => onSelected(values[i]),
              ),
            ),
        ],
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({required this.tab, required this.active, required this.onTap});
  final SegTab tab;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: active ? DS.brand : DS.surface,
      borderRadius: BorderRadius.circular(DS.rPill),
      child: InkWell(
        borderRadius: BorderRadius.circular(DS.rPill),
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: DS.s16, vertical: 9),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(DS.rPill),
            border: Border.all(color: active ? DS.brand : DS.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tab.label,
                style: AppType.bodyStrong.copyWith(
                  color: active ? Colors.white : DS.inkSoft,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (tab.count != null) ...[
                const SizedBox(width: 6),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                  decoration: BoxDecoration(
                    color: active
                        ? Colors.white.withOpacity(0.25)
                        : DS.canvas,
                    borderRadius: BorderRadius.circular(DS.rPill),
                  ),
                  child: Text(
                    '${tab.count}',
                    style: AppType.pill.copyWith(
                      color: active ? Colors.white : DS.muted,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
