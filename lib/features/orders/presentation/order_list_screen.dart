import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/widgets/app_search_bar.dart';
import '../../../core/widgets/modern_data_table.dart';
import '../../../core/widgets/segmented_tabs.dart';
import '../../../core/widgets/state_views.dart';
import '../../../core/widgets/status_pill.dart';
import '../data/order_model.dart';
import '../data/order_status.dart';
import 'order_controller.dart';
import 'order_detail_dialog.dart';

class OrderListScreen extends ConsumerStatefulWidget {
  const OrderListScreen({super.key});

  @override
  ConsumerState<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends ConsumerState<OrderListScreen> {
  final _search = TextEditingController();
  Timer? _debounce;

  static const _currency = '\u20B9';

  // Tab values: null = All, then each status.
  static const _tabValues = <OrderStatus?>[
    null,
    OrderStatus.pending,
    OrderStatus.preparing,
    OrderStatus.outForDelivery,
    OrderStatus.delivered,
    OrderStatus.cancelled,
  ];

  @override
  void dispose() {
    _debounce?.cancel();
    _search.dispose();
    super.dispose();
  }

  void _onSearch(String v) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      ref.read(orderListControllerProvider.notifier).setSearch(v);
    });
  }

  Future<void> _openDetail(Order order) async {
    await showDialog<void>(
      context: context,
      builder: (_) => OrderDetailDialog(order: order),
    );
  }

  String _money(double? v) => v == null
      ? '—'
      : NumberFormat.currency(symbol: _currency, decimalDigits: 0).format(v);

  String _time(DateTime? dt) =>
      dt == null ? '—' : DateFormat('d MMM, h:mm a').format(dt);

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderListControllerProvider);
    final notifier = ref.read(orderListControllerProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(DS.s24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: DS.contentMaxWidth),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Toolbar: search + tabs
              Row(
                children: [
                  AppSearchBar(
                    controller: _search,
                    onChanged: _onSearch,
                    hint: 'Search by customer',
                    width: 300,
                  ),
                ],
              ),
              const SizedBox(height: DS.s16),
              SegmentedTabs<OrderStatus?>(
                values: _tabValues,
                selected: state.status,
                onSelected: notifier.setStatus,
                tabs: const [
                  SegTab('All'),
                  SegTab('Pending'),
                  SegTab('Preparing'),
                  SegTab('Out for delivery'),
                  SegTab('Delivered'),
                  SegTab('Cancelled'),
                ],
              ),
              const SizedBox(height: DS.s20),
              if (state.isLoading)
                const LoadingState()
              else if (state.error != null)
                ErrorState(
                    title: 'Could not load orders',
                    message: state.error!,
                    onRetry: notifier.load)
              else if (state.items.isEmpty)
                const EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'No orders found',
                  message: 'Try a different filter or search term.',
                )
              else
                ModernDataTable(
                  onRowTap: (i) => _openDetail(state.items[i]),
                  columns: const [
                    TableColumn('Order', flex: 2),
                    TableColumn('Customer', flex: 2),
                    TableColumn('Amount', flex: 1),
                    TableColumn('Status', flex: 2),
                    TableColumn('Time', flex: 2),
                  ],
                  footer: _Pager(state: state, notifier: notifier),
                  rows: [
                    for (final o in state.items)
                      TableRowData(cells: [
                        Text('#${o.id ?? '—'}', style: AppType.bodyStrong),
                        Text(o.customerName,
                            style: AppType.body, overflow: TextOverflow.ellipsis),
                        Text(_money(o.totalAmount), style: AppType.bodyStrong),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: StatusPill(
                              label: o.status.label, color: o.status.color),
                        ),
                        Text(_time(o.createdAt), style: AppType.small),
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
          style: AppType.small,
        ),
        const SizedBox(width: DS.s16),
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
