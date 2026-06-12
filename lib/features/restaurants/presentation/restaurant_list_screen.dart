import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/modern_data_table.dart';
import '../../../core/widgets/segmented_tabs.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_pill.dart';
import '../data/restaurant_model.dart';
import '../data/restaurant_repository.dart';
import 'restaurant_form_dialog.dart';
import 'restaurant_list_controller.dart';

class RestaurantListScreen extends ConsumerStatefulWidget {
  const RestaurantListScreen({super.key});

  @override
  ConsumerState<RestaurantListScreen> createState() =>
      _RestaurantListScreenState();
}

class _RestaurantListScreenState extends ConsumerState<RestaurantListScreen> {
  final _search = TextEditingController();
  Timer? _debounce;

  static const _filterValues = [
    ActiveFilter.all,
    ActiveFilter.active,
    ActiveFilter.inactive,
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
        () => ref.read(restaurantListControllerProvider.notifier).setSearch(v));
  }

  void _snack(String m, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
          content: Text(m),
          backgroundColor: error ? DS.danger : DS.success));
  }

  Future<void> _openForm({Restaurant? existing}) async {
    final result = await showDialog<Restaurant>(
      context: context,
      builder: (_) => RestaurantFormDialog(existing: existing),
    );
    if (result == null) return;
    final n = ref.read(restaurantListControllerProvider.notifier);
    final err =
        existing == null ? await n.create(result) : await n.update(result);
    _snack(err ?? (existing == null ? 'Restaurant added' : 'Changes saved'),
        error: err != null);
  }

  Future<void> _confirmDelete(Restaurant r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete restaurant'),
        content: Text('Delete "${r.name}"? This cannot be undone.'),
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
    if (ok != true) return;
    final err =
        await ref.read(restaurantListControllerProvider.notifier).delete(r.id);
    _snack(err ?? 'Restaurant deleted', error: err != null);
  }

  Future<void> _toggle(Restaurant r) async {
    final err = await ref
        .read(restaurantListControllerProvider.notifier)
        .toggleActive(r);
    _snack(err ?? (r.isActive ? 'Deactivated' : 'Activated'),
        error: err != null);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(restaurantListControllerProvider);
    final n = ref.read(restaurantListControllerProvider.notifier);

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
                      hint: 'Search by name',
                      width: 300),
                  const Spacer(),
                  AppButton(
                      label: 'Add restaurant',
                      icon: Icons.add,
                      onPressed: () => _openForm()),
                ],
              ),
              const SizedBox(height: DS.s16),
              SegmentedTabs<ActiveFilter>(
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
                    title: 'Could not load restaurants',
                    message: state.error!,
                    onRetry: n.load)
              else if (state.items.isEmpty)
                const EmptyState(
                    icon: Icons.storefront_outlined,
                    title: 'No restaurants found',
                    message: 'Try a different search or add a new one.')
              else
                ModernDataTable(
                  columns: const [
                    TableColumn('Restaurant', flex: 3),
                    TableColumn('Category', flex: 2),
                    TableColumn('Rating', flex: 1),
                    TableColumn('Status', flex: 1),
                    TableColumn('', fixed: 48),
                  ],
                  footer: _Pager(state: state, notifier: n),
                  rows: [
                    for (final r in state.items)
                      TableRowData(cells: [
                        Row(
                          children: [
                            AppAvatar(
                                label: r.name,
                                imageUrl: r.imageUrl,
                                size: 38,
                                background: DS.violet),
                            const SizedBox(width: DS.s12),
                            Expanded(
                              child: Text(r.name,
                                  style: AppType.bodyStrong,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                        Text(r.category ?? '—', style: AppType.body),
                        Text(
                            r.rating != null
                                ? '★ ${r.rating!.toStringAsFixed(1)}'
                                : '—',
                            style: AppType.body),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: StatusPill.toggle(on: r.isActive),
                        ),
                        _RowMenu(
                          isActive: r.isActive,
                          onEdit: () => _openForm(existing: r),
                          onToggle: () => _toggle(r),
                          onDelete: () => _confirmDelete(r),
                        ),
                      ]),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RowMenu extends StatelessWidget {
  const _RowMenu({
    required this.isActive,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });
  final bool isActive;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: DS.muted),
      onSelected: (v) {
        switch (v) {
          case 'edit':
            onEdit();
          case 'toggle':
            onToggle();
          case 'delete':
            onDelete();
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'edit', child: Text('Edit')),
        PopupMenuItem(
            value: 'toggle',
            child: Text(isActive ? 'Deactivate' : 'Activate')),
        const PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    );
  }
}

class _Pager extends StatelessWidget {
  const _Pager({required this.state, required this.notifier});
  final RestaurantListState state;
  final RestaurantListController notifier;

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
