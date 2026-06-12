import 'dart:async';

import 'package:flutter/material.dart' hide MenuController;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dropdown.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/widgets/avatar.dart';
import '../../../core/widgets/modern_data_table.dart';
import '../../../core/widgets/segmented_tabs.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_pill.dart';
import '../../auth/presentation/current_profile_provider.dart';
import '../data/menu_item_model.dart';
import '../data/menu_repository.dart';
import 'menu_controller.dart';
import 'menu_form_dialog.dart';

class MenuScreen extends ConsumerStatefulWidget {
  const MenuScreen({super.key});

  @override
  ConsumerState<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends ConsumerState<MenuScreen> {
  final _search = TextEditingController();
  Timer? _debounce;

  static const _currency = '\u20B9';
  static const _vegValues = [VegFilter.all, VegFilter.veg, VegFilter.nonVeg];
  static const _availValues = [
    AvailabilityFilter.all,
    AvailabilityFilter.available,
    AvailabilityFilter.unavailable,
  ];

  @override
  void initState() {
    super.initState();
    // RBAC: an owner's menu is locked to their own restaurant. (Unchanged.)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(currentUserOrNullProvider);
      if (user != null && user.isOwner) {
        final rid = user.primaryRestaurantId;
        if (rid != null) {
          ref.read(menuControllerProvider.notifier).setRestaurant(rid);
        }
      }
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400),
        () => ref.read(menuControllerProvider.notifier).setSearch(v));
  }

  void _snack(String m, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
          content: Text(m),
          backgroundColor: error ? DS.danger : DS.success));
  }

  Future<void> _openForm({MenuItem? existing}) async {
    final state = ref.read(menuControllerProvider);
    final user = ref.read(currentUserOrNullProvider);
    final isOwner = user?.isOwner ?? false;
    final lockedRestaurantId = isOwner ? user?.primaryRestaurantId : null;

    if (isOwner && lockedRestaurantId == null) {
      _snack('No restaurant is linked to your account yet.', error: true);
      return;
    }
    if (!isOwner && state.restaurantNames.isEmpty) {
      _snack('Add a restaurant first before creating menu items.',
          error: true);
      return;
    }

    final result = await showDialog<MenuItem>(
      context: context,
      builder: (_) => MenuFormDialog(
        restaurantNames: state.restaurantNames,
        existing: existing,
        isOwner: isOwner,
        lockedRestaurantId: lockedRestaurantId,
      ),
    );
    if (result == null) return;
    final n = ref.read(menuControllerProvider.notifier);
    final err =
        existing == null ? await n.create(result) : await n.update(result);
    _snack(err ?? (existing == null ? 'Menu item added' : 'Changes saved'),
        error: err != null);
  }

  Future<void> _confirmDelete(MenuItem item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete menu item'),
        content: Text('Delete "${item.name}"? This cannot be undone.'),
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
    if (ok != true || item.id == null) return;
    final err = await ref.read(menuControllerProvider.notifier).delete(item.id!);
    _snack(err ?? 'Menu item deleted', error: err != null);
  }

  Future<void> _toggle(MenuItem item) async {
    final err =
        await ref.read(menuControllerProvider.notifier).toggleAvailable(item);
    _snack(err ?? (item.isAvailable ? 'Marked unavailable' : 'Marked available'),
        error: err != null);
  }

  String _money(double? v) => v == null
      ? '—'
      : NumberFormat.currency(symbol: _currency, decimalDigits: 0).format(v);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(menuControllerProvider);
    final n = ref.read(menuControllerProvider.notifier);
    final isOwner = ref.watch(currentUserOrNullProvider)?.isOwner ?? false;

    final restaurantEntries = state.restaurantNames.entries.toList()
      ..sort((a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()));

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
                      hint: 'Search menu items',
                      width: 280),
                  const Spacer(),
                  AppButton(
                      label: 'Add item',
                      icon: Icons.add,
                      onPressed: () => _openForm()),
                ],
              ),
              const SizedBox(height: DS.s16),
              Wrap(
                spacing: DS.s12,
                runSpacing: DS.s12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  if (!isOwner)
                    AppDropdown<int?>(
                      value: state.restaurantId,
                      width: 220,
                      hint: 'All restaurants',
                      items: [
                        const DropdownItem<int?>(null, 'All restaurants'),
                        for (final e in restaurantEntries)
                          DropdownItem<int?>(e.key, e.value),
                      ],
                      onChanged: n.setRestaurant,
                    ),
                  SegmentedTabs<VegFilter>(
                    values: _vegValues,
                    selected: state.veg,
                    onSelected: n.setVeg,
                    tabs: const [
                      SegTab('All'),
                      SegTab('Veg'),
                      SegTab('Non-veg'),
                    ],
                  ),
                  SegmentedTabs<AvailabilityFilter>(
                    values: _availValues,
                    selected: state.availability,
                    onSelected: n.setAvailability,
                    tabs: const [
                      SegTab('All'),
                      SegTab('Available'),
                      SegTab('Unavailable'),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: DS.s20),
              if (state.isLoading)
                const LoadingState()
              else if (state.error != null)
                ErrorState(
                    title: 'Could not load menu items',
                    message: state.error!,
                    onRetry: n.load)
              else if (state.items.isEmpty)
                const EmptyState(
                    icon: Icons.restaurant_menu_outlined,
                    title: 'No menu items found',
                    message: 'Try different filters or add a new item.')
              else
                ModernDataTable(
                  columns: const [
                    TableColumn('Item', flex: 3),
                    TableColumn('Restaurant', flex: 2),
                    TableColumn('Price', flex: 1),
                    TableColumn('Status', flex: 1),
                    TableColumn('', fixed: 48),
                  ],
                  footer: _Pager(state: state, notifier: n),
                  rows: [
                    for (final m in state.items)
                      TableRowData(cells: [
                        Row(
                          children: [
                            AppAvatar(
                                label: m.name,
                                imageUrl: m.imageUrl,
                                size: 38,
                                background: DS.success),
                            const SizedBox(width: DS.s12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(m.name,
                                      style: AppType.bodyStrong,
                                      overflow: TextOverflow.ellipsis),
                                  Row(children: [
                                    _VegDot(isVeg: m.isVeg),
                                    const SizedBox(width: 6),
                                    Text(m.category ?? '—',
                                        style: AppType.small),
                                  ]),
                                ],
                              ),
                            ),
                          ],
                        ),
                        Text(state.restaurantNames[m.restaurantId] ?? '—',
                            style: AppType.body,
                            overflow: TextOverflow.ellipsis),
                        Text(_money(m.price), style: AppType.bodyStrong),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: StatusPill.toggle(
                              on: m.isAvailable,
                              onLabel: 'Available',
                              offLabel: 'Unavailable'),
                        ),
                        _RowMenu(
                          available: m.isAvailable,
                          onEdit: () => _openForm(existing: m),
                          onToggle: () => _toggle(m),
                          onDelete: () => _confirmDelete(m),
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

class _VegDot extends StatelessWidget {
  const _VegDot({required this.isVeg});
  final bool isVeg;

  @override
  Widget build(BuildContext context) {
    final color = isVeg ? DS.success : DS.danger;
    return Container(
      width: 13,
      height: 13,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Center(
        child: Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      ),
    );
  }
}

class _RowMenu extends StatelessWidget {
  const _RowMenu({
    required this.available,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });
  final bool available;
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
            child: Text(available ? 'Mark unavailable' : 'Mark available')),
        const PopupMenuItem(value: 'delete', child: Text('Delete')),
      ],
    );
  }
}

class _Pager extends StatelessWidget {
  const _Pager({required this.state, required this.notifier});
  final MenuListState state;
  final MenuController notifier;

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
