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
import '../../auth/presentation/current_profile_provider.dart';
import '../../delivery_partners/data/delivery_partner_model.dart';
import '../../delivery_partners/data/delivery_partner_profiles_provider.dart';
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

  void _snack(String m, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
          content: Text(m),
          backgroundColor: error ? DS.danger : DS.success));
  }

  /// Super-admin-only: pick a rider (or unassign) for [order].
  Future<void> _openAssign(
      Order order, List<DeliveryPartner> partners) async {
    if (order.id == null) return;
    final result = await showDialog<_AssignResult>(
      context: context,
      builder: (_) => _AssignRiderDialog(
        order: order,
        partners: partners,
      ),
    );
    if (result == null) return; // cancelled

    final n = ref.read(orderListControllerProvider.notifier);
    final String? err;
    if (result.unassign) {
      err = await n.unassignPartner(order.id!);
    } else if (result.partnerId != null) {
      err = await n.assignPartner(order.id!, result.partnerId!);
    } else {
      return;
    }
    _snack(err ?? (result.unassign ? 'Rider unassigned' : 'Rider assigned'),
        error: err != null);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(orderListControllerProvider);
    final notifier = ref.read(orderListControllerProvider.notifier);

    final isSuperAdmin =
        ref.watch(currentUserOrNullProvider)?.isSuperAdmin ?? false;

    // id -> partner name for the Assigned rider column.
    final partnersAsync = ref.watch(activeDeliveryPartnersProvider);
    final partners =
        partnersAsync.asData?.value ?? const <DeliveryPartner>[];
    final partnerNameById = <int, String>{
      for (final p in partners)
        if (p.id != null) p.id!: p.name,
    };

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
                    TableColumn('Assigned rider', flex: 2),
                    TableColumn('Time', flex: 2),
                    TableColumn('', fixed: 56),
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
                        _RiderCell(
                          partnerId: o.deliveryPartnerId,
                          name: o.deliveryPartnerId == null
                              ? null
                              : partnerNameById[o.deliveryPartnerId],
                        ),
                        Text(_time(o.createdAt), style: AppType.small),
                        // Assign action — super admin only. Empty cell otherwise
                        // so owners still see the row (and the rider column).
                        if (isSuperAdmin)
                          IconButton(
                            tooltip: o.deliveryPartnerId == null
                                ? 'Assign rider'
                                : 'Reassign rider',
                            icon: Icon(
                              o.deliveryPartnerId == null
                                  ? Icons.person_add_alt
                                  : Icons.swap_horiz,
                              color: DS.brand,
                              size: 20,
                            ),
                            onPressed: () => _openAssign(o, partners),
                          )
                        else
                          const SizedBox.shrink(),
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

class _RiderCell extends StatelessWidget {
  const _RiderCell({required this.partnerId, required this.name});
  final int? partnerId;
  final String? name;

  @override
  Widget build(BuildContext context) {
    if (partnerId == null) {
      return Text('Unassigned',
          style: AppType.small.copyWith(color: DS.muted));
    }
    if (name != null && name!.isNotEmpty) {
      return Row(
        children: [
          const Icon(Icons.delivery_dining_outlined,
              size: 16, color: DS.info),
          const SizedBox(width: 6),
          Expanded(
            child: Text(name!,
                style: AppType.body, overflow: TextOverflow.ellipsis),
          ),
        ],
      );
    }
    // Assigned, but the partner isn't in the active list (inactive/loading).
    return Row(
      children: [
        const Icon(Icons.delivery_dining_outlined, size: 16, color: DS.muted),
        const SizedBox(width: 6),
        Text('Assigned', style: AppType.small),
      ],
    );
  }
}

class _AssignResult {
  const _AssignResult({this.partnerId, this.unassign = false});
  final int? partnerId;
  final bool unassign;
}

class _AssignRiderDialog extends StatefulWidget {
  const _AssignRiderDialog({required this.order, required this.partners});
  final Order order;
  final List<DeliveryPartner> partners;

  @override
  State<_AssignRiderDialog> createState() => _AssignRiderDialogState();
}

class _AssignRiderDialogState extends State<_AssignRiderDialog> {
  int? _selected;

  @override
  void initState() {
    super.initState();
    // Preselect the current assignment if it's among the active partners.
    final current = widget.order.deliveryPartnerId;
    final ids = widget.partners.map((p) => p.id).whereType<int>().toSet();
    _selected = (current != null && ids.contains(current)) ? current : null;
  }

  @override
  Widget build(BuildContext context) {
    final isAssigned = widget.order.deliveryPartnerId != null;
    return AlertDialog(
      backgroundColor: DS.surface,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(DS.rLg)),
      title: Text(isAssigned ? 'Reassign rider' : 'Assign rider',
          style: AppType.h2),
      content: SizedBox(
        width: 380,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order #${widget.order.id ?? '—'}', style: AppType.small),
            const SizedBox(height: DS.s16),
            if (widget.partners.isEmpty)
              Text('No active delivery partners available.',
                  style: AppType.body)
            else
              DropdownButtonFormField<int>(
                value: _selected,
                isExpanded: true,
                hint: const Text('Select a rider'),
                items: [
                  for (final p in widget.partners)
                    if (p.id != null)
                      DropdownMenuItem<int>(
                        value: p.id,
                        child: Text(
                          p.phone == null || p.phone!.isEmpty
                              ? p.name
                              : '${p.name} · ${p.phone}',
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                ],
                onChanged: (v) => setState(() => _selected = v),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        if (isAssigned)
          TextButton(
            onPressed: () => Navigator.of(context)
                .pop(const _AssignResult(unassign: true)),
            child: const Text('Unassign',
                style: TextStyle(color: DS.danger)),
          ),
        FilledButton(
          onPressed: _selected == null
              ? null
              : () => Navigator.of(context)
                  .pop(_AssignResult(partnerId: _selected)),
          child: Text(isAssigned ? 'Reassign' : 'Assign'),
        ),
      ],
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
