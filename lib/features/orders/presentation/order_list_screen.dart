import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../data/order_model.dart';
import '../data/order_status.dart';
import 'order_controller.dart';
import 'order_detail_dialog.dart';
import 'status_chip.dart';

class OrderListScreen extends ConsumerStatefulWidget {
  const OrderListScreen({super.key});

  @override
  ConsumerState<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends ConsumerState<OrderListScreen> {
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
      ref.read(orderListControllerProvider.notifier).setSearch(value);
    });
  }

  Future<void> _openDetail(Order order) async {
    await showDialog<void>(
      context: context,
      builder: (_) => OrderDetailDialog(order: order),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderListControllerProvider);
    final notifier = ref.read(orderListControllerProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('MANAGEMENT', style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 4),
          Text('Orders', style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 22),
          _Toolbar(
            searchController: _searchController,
            onSearchChanged: _onSearchChanged,
            status: state.status,
            onStatusChanged: notifier.setStatus,
          ),
          const SizedBox(height: 16),
          _Content(
            state: state,
            onRetry: notifier.load,
            onTap: _openDetail,
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
    required this.status,
    required this.onStatusChanged,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final OrderStatus? status;
  final ValueChanged<OrderStatus?> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 300,
          child: TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            decoration: const InputDecoration(
              hintText: 'Search by customer name',
              prefixIcon: Icon(Icons.search, color: AppColors.muted),
            ),
          ),
        ),
        SizedBox(
          width: 220,
          child: DropdownButtonFormField<OrderStatus?>(
            value: status,
            isExpanded: true,
            decoration: const InputDecoration(labelText: 'Status'),
            items: [
              const DropdownMenuItem<OrderStatus?>(
                  value: null, child: Text('All statuses')),
              for (final s in OrderStatus.assignable)
                DropdownMenuItem<OrderStatus?>(
                    value: s, child: Text(s.label)),
            ],
            onChanged: onStatusChanged,
          ),
        ),
      ],
    );
  }
}

class _Content extends StatelessWidget {
  const _Content({
    required this.state,
    required this.onRetry,
    required this.onTap,
  });

  final OrderListState state;
  final VoidCallback onRetry;
  final ValueChanged<Order> onTap;

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
            Text('Could not load orders',
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
            const Icon(Icons.receipt_long_outlined,
                color: AppColors.muted, size: 36),
            const SizedBox(height: 12),
            Text('No orders found',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text('Try a different search or status filter.',
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
            _OrderRow(order: state.items[i], onTap: () => onTap(state.items[i])),
          ],
        ],
      ),
    );
  }
}

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order, required this.onTap});
  final Order order;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final dateText = order.createdAt == null
        ? null
        : DateFormat('d MMM, h:mm a').format(order.createdAt!.toLocal());

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.cream,
              child: Text(
                _initials(order.customerName),
                style: const TextStyle(
                    color: AppColors.saffronDeep,
                    fontWeight: FontWeight.w700,
                    fontSize: 14),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    order.customerName.isEmpty
                        ? 'Unnamed customer'
                        : order.customerName,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [
                      if (order.id != null) '#${order.id}',
                      if (dateText != null) dateText,
                      if (order.phone != null && order.phone!.isNotEmpty)
                        order.phone,
                    ].whereType<String>().join('  ·  '),
                    style: Theme.of(context).textTheme.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              order.totalAmount != null
                  ? '₹${order.totalAmount!.toStringAsFixed(2)}'
                  : '—',
              style: const TextStyle(
                  fontWeight: FontWeight.w700, color: AppColors.ink),
            ),
            const SizedBox(width: 14),
            StatusChip(status: order.status),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: AppColors.muted),
          ],
        ),
      ),
    );
  }

  String _initials(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.characters.take(1).toString().toUpperCase();
    }
    return (parts.first.characters.take(1).toString() +
            parts.last.characters.take(1).toString())
        .toUpperCase();
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
  final OrderListState state;
  final OrderListController notifier;

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
