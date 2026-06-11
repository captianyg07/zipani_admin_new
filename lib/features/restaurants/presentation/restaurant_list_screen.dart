import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_theme.dart';
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
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(restaurantListControllerProvider.notifier).setSearch(value);
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

  Future<void> _openForm({Restaurant? existing}) async {
    final result = await showDialog<Restaurant>(
      context: context,
      builder: (_) => RestaurantFormDialog(existing: existing),
    );
    if (result == null) return;

    final notifier = ref.read(restaurantListControllerProvider.notifier);
    final error = existing == null
        ? await notifier.create(result)
        : await notifier.update(result);

    if (error == null) {
      _snack(existing == null ? 'Restaurant added' : 'Changes saved');
    } else {
      _snack(error, error: true);
    }
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

    final error =
        await ref.read(restaurantListControllerProvider.notifier).delete(r.id);
    _snack(error ?? 'Restaurant deleted', error: error != null);
  }

  Future<void> _toggleActive(Restaurant r) async {
    final error = await ref
        .read(restaurantListControllerProvider.notifier)
        .toggleActive(r);
    _snack(
      error ?? (r.isActive ? 'Restaurant deactivated' : 'Restaurant activated'),
      error: error != null,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(restaurantListControllerProvider);
    final notifier = ref.read(restaurantListControllerProvider.notifier);

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
                    Text('Restaurants',
                        style: Theme.of(context).textTheme.displaySmall),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: () => _openForm(),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add restaurant'),
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
            filter: state.filter,
            onFilterChanged: notifier.setFilter,
          ),
          const SizedBox(height: 16),
          _Content(
            state: state,
            onRetry: notifier.load,
            onEdit: (r) => _openForm(existing: r),
            onDelete: _confirmDelete,
            onToggle: _toggleActive,
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
    required this.filter,
    required this.onFilterChanged,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ActiveFilter filter;
  final ValueChanged<ActiveFilter> onFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 320,
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: const InputDecoration(
              hintText: 'Search by name',
              prefixIcon: Icon(Icons.search, color: AppColors.muted),
            ),
          ),
        ),
        SegmentedButton<ActiveFilter>(
          segments: const [
            ButtonSegment(value: ActiveFilter.all, label: Text('All')),
            ButtonSegment(value: ActiveFilter.active, label: Text('Active')),
            ButtonSegment(
                value: ActiveFilter.inactive, label: Text('Inactive')),
          ],
          selected: {filter},
          onSelectionChanged: (s) => onFilterChanged(s.first),
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

  final RestaurantListState state;
  final VoidCallback onRetry;
  final ValueChanged<Restaurant> onEdit;
  final ValueChanged<Restaurant> onDelete;
  final ValueChanged<Restaurant> onToggle;

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
            Text('Could not load restaurants',
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
            const Icon(Icons.storefront_outlined,
                color: AppColors.muted, size: 36),
            const SizedBox(height: 12),
            Text('No restaurants found',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text('Try a different search or add a new restaurant.',
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
            _RestaurantRow(
              restaurant: state.items[i],
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

class _RestaurantRow extends StatelessWidget {
  const _RestaurantRow({
    required this.restaurant,
    required this.onEdit,
    required this.onDelete,
    required this.onToggle,
  });

  final Restaurant restaurant;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final r = restaurant;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          _Thumb(url: r.imageUrl),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(r.name,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium),
                    ),
                    if (r.isVeg) ...[
                      const SizedBox(width: 8),
                      const _VegBadge(),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  [
                    if (r.category != null) r.category,
                    if (r.rating != null) '★ ${r.rating!.toStringAsFixed(1)}',
                    if (r.deliveryTime != null) r.deliveryTime,
                  ].whereType<String>().join('  ·  '),
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _StatusChip(active: r.isActive),
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
                child: Text(r.isActive ? 'Deactivate' : 'Activate'),
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
                child: const Icon(Icons.storefront_outlined,
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

class _VegBadge extends StatelessWidget {
  const _VegBadge();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.positive),
        borderRadius: BorderRadius.circular(4),
      ),
      child: const Text('VEG',
          style: TextStyle(
              color: AppColors.positive,
              fontSize: 10,
              fontWeight: FontWeight.w700)),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.positive : AppColors.muted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        active ? 'Active' : 'Inactive',
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
  final RestaurantListState state;
  final RestaurantListController notifier;

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
