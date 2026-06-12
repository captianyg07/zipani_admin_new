import 'dart:async';

import 'package:flutter/material.dart' hide Banner;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_card.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/widgets/segmented_tabs.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_pill.dart';
import '../data/banner_model.dart';
import '../data/banner_repository.dart';
import 'banner_controller.dart';
import 'banner_form_dialog.dart';

class BannerScreen extends ConsumerStatefulWidget {
  const BannerScreen({super.key});

  @override
  ConsumerState<BannerScreen> createState() => _BannerScreenState();
}

class _BannerScreenState extends ConsumerState<BannerScreen> {
  final _search = TextEditingController();
  Timer? _debounce;

  static const _filterValues = [
    BannerActiveFilter.all,
    BannerActiveFilter.active,
    BannerActiveFilter.inactive,
  ];

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400),
        () => ref.read(bannerControllerProvider.notifier).setSearch(v));
  }

  void _snack(String m, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
          content: Text(m),
          backgroundColor: error ? DS.danger : DS.success));
  }

  Future<void> _openForm({Banner? existing}) async {
    final result = await showDialog<Banner>(
      context: context,
      builder: (_) => BannerFormDialog(existing: existing),
    );
    if (result == null) return;
    final n = ref.read(bannerControllerProvider.notifier);
    final err =
        existing == null ? await n.create(result) : await n.update(result);
    _snack(err ?? (existing == null ? 'Banner added' : 'Changes saved'),
        error: err != null);
  }

  Future<void> _confirmDelete(Banner b) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete banner'),
        content: Text('Delete "${b.title}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: DS.danger),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || b.id == null) return;
    final err = await ref.read(bannerControllerProvider.notifier).delete(b.id!);
    _snack(err ?? 'Banner deleted', error: err != null);
  }

  Future<void> _toggle(Banner b) async {
    final err =
        await ref.read(bannerControllerProvider.notifier).toggleActive(b);
    _snack(err ?? (b.isActive ? 'Deactivated' : 'Activated'),
        error: err != null);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(bannerControllerProvider);
    final n = ref.read(bannerControllerProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DS.s24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: DS.contentMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AppSearchBar(
                      controller: _search,
                      onChanged: _onSearch,
                      hint: 'Search campaigns',
                      width: 300),
                  const Spacer(),
                  AppButton(
                      label: 'Create offer',
                      icon: Icons.add,
                      onPressed: () => _openForm()),
                ],
              ),
              const SizedBox(height: DS.s16),
              SegmentedTabs<BannerActiveFilter>(
                values: _filterValues,
                selected: state.filter,
                onSelected: n.setFilter,
                tabs: const [
                  SegTab('All'),
                  SegTab('Active'),
                  SegTab('Inactive'),
                ],
              ),
              const SizedBox(height: DS.s20),
              if (state.isLoading)
                const LoadingState()
              else if (state.error != null)
                ErrorState(
                    title: 'Could not load campaigns',
                    message: state.error!,
                    onRetry: n.load)
              else if (state.items.isEmpty)
                const EmptyState(
                    icon: Icons.campaign_outlined,
                    title: 'No campaigns found',
                    message: 'Create your first offer to get started.')
              else
                LayoutBuilder(builder: (context, c) {
                  final cols = c.maxWidth >= 1100
                      ? 3
                      : c.maxWidth >= 720
                          ? 2
                          : 1;
                  const gap = DS.s16;
                  final w = (c.maxWidth - (cols - 1) * gap) / cols;
                  return Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final b in state.items)
                        SizedBox(
                          width: w,
                          child: _CampaignCard(
                            banner: b,
                            onEdit: () => _openForm(existing: b),
                            onToggle: () => _toggle(b),
                            onDelete: () => _confirmDelete(b),
                          ),
                        ),
                    ],
                  );
                }),
              const SizedBox(height: DS.s16),
              if (!state.isLoading &&
                  state.error == null &&
                  state.items.isNotEmpty)
                _Pager(state: state, notifier: n),
            ],
          ),
        ),
      ),
    );
  }
}

class _CampaignCard extends StatelessWidget {
  const _CampaignCard({
    required this.banner,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });
  final Banner banner;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final b = banner;
    return AppCard(
      padding: EdgeInsets.zero,
      clip: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 16 / 7,
            child: b.imageUrl.isEmpty
                ? Container(
                    color: DS.canvasAlt,
                    child: const Icon(Icons.image_outlined,
                        color: DS.muted, size: 30))
                : Image.network(b.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                          color: DS.canvasAlt,
                          child: const Icon(Icons.broken_image_outlined,
                              color: DS.muted, size: 30),
                        )),
          ),
          Padding(
            padding: const EdgeInsets.all(DS.s16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(b.title,
                          style: AppType.h3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    StatusPill.toggle(on: b.isActive),
                  ],
                ),
                if (b.subtitle != null && b.subtitle!.isNotEmpty) ...[
                  const SizedBox(height: DS.s4),
                  Text(b.subtitle!,
                      style: AppType.small,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
                const SizedBox(height: DS.s12),
                const Divider(height: 1, color: DS.line),
                const SizedBox(height: DS.s4),
                Row(
                  children: [
                    TextButton.icon(
                        onPressed: onEdit,
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Edit')),
                    const Spacer(),
                    IconButton(
                        tooltip: b.isActive ? 'Deactivate' : 'Activate',
                        onPressed: onToggle,
                        icon: Icon(
                            b.isActive
                                ? Icons.toggle_on
                                : Icons.toggle_off_outlined,
                            color: b.isActive ? DS.success : DS.muted)),
                    IconButton(
                        tooltip: 'Delete',
                        onPressed: onDelete,
                        icon: const Icon(Icons.delete_outline,
                            color: DS.danger, size: 20)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pager extends StatelessWidget {
  const _Pager({required this.state, required this.notifier});
  final BannerListState state;
  final BannerController notifier;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
            'Page ${state.page + 1} of ${state.totalPages}  ·  ${state.totalCount} total',
            style: AppType.small),
        const SizedBox(width: DS.s16),
        IconButton(
            onPressed: state.hasPrev ? notifier.prevPage : null,
            icon: const Icon(Icons.chevron_left)),
        IconButton(
            onPressed: state.hasNext ? notifier.nextPage : null,
            icon: const Icon(Icons.chevron_right)),
      ],
    );
  }
}
