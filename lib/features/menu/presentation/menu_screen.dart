import 'dart:async';

import 'package:flutter/material.dart' hide MenuController;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
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
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    // Defense in depth: an owner's menu is locked to their own restaurant.
    // RLS already blocks cross-restaurant rows; this keeps the UI honest.
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
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(menuControllerProvider.notifier).setSearch(value);
    });
  }

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.danger : AppColors.positive,
      ));
  }

  Future<void> _openForm({MenuItem? existing}) async {
    final state = ref.read(menuControllerProvider);
    final user = ref.read(currentUserOrNullProvider);
    final isOwner = user?.isOwner ?? false;
    final lockedRestaurantId = isOwner ? user?.primaryRestaurantId : null;

    // Owners must have a resolved restaurant before they can add items.
    if (isOwner && lockedRestaurantId == null) {
      _snack('No restaurant is linked to your account yet. '
          'Please contact an administrator.', error: true);
      return;
    }
    // Super admin needs at least one restaurant to assign items to.
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

    final notifier = ref.read(menuControllerProvider.notifier);
    final error = existing == null
        ? await notifier.create(result)
        : await notifier.update(result);

    if (error == null) {
      _snack(existing == null ? 'Menu item added' : 'Changes saved');
    } else {
      _snack(error, error: true);
    }
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
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    if (item.id == null) return;

    final error =
        await ref.read(menuControllerProvider.notifier).delete(item.id!);
    _snack(error ?? 'Menu item deleted', error: error != null);
  }

  Future<void> _toggleAvailable(MenuItem item) async {
    final error =
        await ref.read(menuControllerProvider.notifier).toggleAvailable(item);
    _snack(
      error ??
          (item.isAvailable ? 'Marked unavailable' : 'Marked available'),
      error: error != null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(menuControllerProvider);
    final notifier = ref.read(menuControllerProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('MANAGEMENT',
                        style: Theme.of(context).textTheme.labelLarge),
                    const SizedBox(height: 4),
                    Text('Menu',
                        style: Theme.of(context).textTheme.displaySmall),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => _openForm(),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add item'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _Toolbar(
            searchController: _searchController,
            onSearchChanged: _onSearchChanged,
            state: state,
            notifier: notifier,
            showRestaurantFilter:
                !(ref.watch(currentUserOrNullProvider)?.isOwner ?? false),
          ),
          const SizedBox(height: 16),
          _Content(
            state: state,
            onRetry: notifier.load,
            onEdit: (m) => _openForm(existing: m),
            onDelete: _confirmDelete,
            onToggle: _toggleAvailable,
          ),
          const SizedBox(height: 16),
          if (!state.isLoading && state.error == null && state.items.isNotEmpty)
            _Pager(state: state, notifier: notifier),
        ],
      ),
    );
  }
}

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.searchController,
    required this.onSearchChanged,
    required this.state,
    required this.notifier,
    this.showRestaurantFilter = true,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final MenuListState state;
  final MenuController notifier;
  final bool showRestaurantFilter;

  @override
  Widget build(BuildContext context) {
    final restaurantEntries = state.restaurantNames.entries.toList()
      ..sort((a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()));

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 280,
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: const InputDecoration(
              hintText: 'Search by item name',
              prefixIcon: Icon(Icons.search, color: AppColors.muted),
            ),
          ),
        ),
        if (showRestaurantFilter)
          SizedBox(
            width: 220,
            child: DropdownButtonFormField<int?>(
              value: state.restaurantId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Restaurant'),
              items: [
                const DropdownMenuItem<int?>(
                    value: null, child: Text('All restaurants')),
                for (final e in restaurantEntries)
                  DropdownMenuItem<int?>(
                    value: e.key,
                    child: Text(e.value, overflow: TextOverflow.ellipsis),
                  ),
              ],
              onChanged: notifier.setRestaurant,
            ),
          ),
        SegmentedButton<VegFilter>(
          segments: const [
            ButtonSegment(value: VegFilter.all, label: Text('All')),
            ButtonSegment(value: VegFilter.veg, label: Text('Veg')),
            ButtonSegment(value: VegFilter.nonVeg, label: Text('Non-veg')),
          ],
          selected: {state.veg},
          onSelectionChanged: (s) => notifier.setVeg(s.first),
        ),
        SegmentedButton<AvailabilityFilter>(
          segments: const [
            ButtonSegment(
                value: AvailabilityFilter.all, label: Text('All')),
            ButtonSegment(
                value: AvailabilityFilter.available,
                label: Text('Available')),
            ButtonSegment(
                value: AvailabilityFilter.unavailable,
                label: Text('Unavailable')),
          ],
          selected: {state.availability},
          onSelectionChanged: (s) => notifier.setAvailability(s.first),
        ),
      ],
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.state,
    required this.onRetry,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  final MenuListState state;
  final VoidCallback onRetry;
  final ValueChanged<MenuItem> onEdit;
  final ValueChanged<MenuItem> onDelete;
  final ValueChanged<MenuItem> onToggle;

  @override
  Widget build(BuildContext context) {
    if (state.isLoading) {
      return const SizedBox(
        height: 280,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (state.error != null) {
      return _Panel(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: AppColors.danger, size: 36),
            const SizedBox(height: 12),
            Text('Could not load menu items',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(state.error!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      );
    }
    if (state.items.isEmpty) {
      return _Panel(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.restaurant_menu_outlined,
                color: AppColors.muted, size: 36),
            const SizedBox(height: 12),
            Text('No menu items found',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text('Try different filters or add a new item.',
                style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          for (var i = 0; i < state.items.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.line),
            _MenuRow(
              item: state.items[i],
              restaurantName: state.restaurantName(state.items[i].restaurantId),
              onEdit: () => onEdit(state.items[i]),
              onDelete: () => onDelete(state.items[i]),
              onToggle: () => onToggle(state.items[i]),
            ),
          ],
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  const _MenuRow({
    required this.item,
    required this.restaurantName,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  final MenuItem item;
  final String restaurantName;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _Thumb(url: item.imageUrl),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(item.name,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium),
                    ),
                    const SizedBox(width: 8),
                    _VegDot(isVeg: item.isVeg),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    restaurantName,
                    if (item.category != null) item.category,
                    if (item.price != null)
                      '₹${item.price!.toStringAsFixed(2)}',
                  ].whereType<String>().join('  ·  '),
                  style: Theme.of(context).textTheme.bodyMedium,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _AvailabilityChip(available: item.isAvailable),
          const SizedBox(width: 4),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: AppColors.muted),
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
                child: Text(
                    item.isAvailable ? 'Mark unavailable' : 'Mark available'),
              ),
              const PopupMenuItem(value: 'delete', child: Text('Delete')),
            ],
          ),
        ],
      ),
    );
  }
}

class _Thumb extends StatelessWidget {
  const _Thumb({this.url});
  final String? url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(9),
      child: SizedBox(
        width: 48,
        height: 48,
        child: url == null || url!.isEmpty
            ? Container(
                color: AppColors.cream,
                child: const Icon(Icons.restaurant_menu_outlined,
                    color: AppColors.muted, size: 20),
              )
            : Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: AppColors.cream,
                  child: const Icon(Icons.broken_image_outlined,
                      color: AppColors.muted, size: 20),
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
    final color = isVeg ? AppColors.positive : AppColors.danger;
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Center(
        child: Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
      ),
    );
  }
}

class _AvailabilityChip extends StatelessWidget {
  const _AvailabilityChip({required this.available});
  final bool available;

  @override
  Widget build(BuildContext context) {
    final color = available ? AppColors.positive : AppColors.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        available ? 'Available' : 'Unavailable',
        style: TextStyle(
            color: color, fontSize: 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Center(child: child),
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
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(width: 16),
        IconButton(
          onPressed: state.hasPrev ? notifier.prevPage : null,
          icon: const Icon(Icons.chevron_left),
        ),
        IconButton(
          onPressed: state.hasNext ? notifier.nextPage : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }
}
