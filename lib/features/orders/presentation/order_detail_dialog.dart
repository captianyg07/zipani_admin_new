import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialog.dart';
import '../../../core/widgets/status_pill.dart';
import '../data/order_status.dart';
import '../data/order_model.dart';
import 'order_controller.dart';

class OrderDetailDialog extends ConsumerStatefulWidget {
  const OrderDetailDialog({super.key, required this.order});
  final Order order;

  @override
  ConsumerState<OrderDetailDialog> createState() => _OrderDetailDialogState();
}

class _OrderDetailDialogState extends ConsumerState<OrderDetailDialog> {
  late OrderStatus _selectedStatus;
  bool _saving = false;

  static const _currency = '\u20B9';

  @override
  void initState() {
    super.initState();
    _selectedStatus = widget.order.status == OrderStatus.unknown
        ? OrderStatus.pending
        : widget.order.status;
  }

  Future<void> _saveStatus() async {
    final id = widget.order.id;
    if (id == null) return;
    setState(() => _saving = true);
    final error = await ref
        .read(orderListControllerProvider.notifier)
        .updateStatus(id, _selectedStatus);
    if (!mounted) return;
    setState(() => _saving = false);

    if (error == null) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(
          content: Text('Order status updated'),
          backgroundColor: DS.success,
        ));
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
            content: Text(error), backgroundColor: DS.danger));
    }
  }

  String _money(double? v) => v == null
      ? '—'
      : NumberFormat.currency(symbol: _currency, decimalDigits: 0).format(v);

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final id = order.id;
    final dateText = order.createdAt == null
        ? null
        : DateFormat('d MMM yyyy, h:mm a').format(order.createdAt!.toLocal());

    return AppDialog(
      title: id == null ? 'Order' : 'Order #$id',
      maxWidth: 540,
      actions: [
        AppButton(
          label: 'Close',
          variant: AppButtonVariant.ghost,
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
        ),
        AppButton(
          label: _saving ? 'Saving…' : 'Save status',
          onPressed: (_saving || _selectedStatus == order.status)
              ? null
              : _saveStatus,
        ),
      ],
      children: [
        Row(
          children: [
            StatusPill(label: order.status.label, color: order.status.color),
            const Spacer(),
            if (dateText != null) Text(dateText, style: AppType.small),
          ],
        ),
        const SizedBox(height: DS.s20),
        const _Label('CUSTOMER'),
        const SizedBox(height: DS.s8),
        _InfoRow(Icons.person_outline, order.customerName),
        if (order.phone != null && order.phone!.isNotEmpty)
          _InfoRow(Icons.phone_outlined, order.phone!),
        if (order.address != null && order.address!.isNotEmpty)
          _InfoRow(Icons.location_on_outlined, order.address!),
        const SizedBox(height: DS.s20),
        const _Label('ITEMS'),
        const SizedBox(height: DS.s8),
        if (id == null)
          Text('No order id — items unavailable.', style: AppType.body)
        else
          _ItemsList(orderId: id),
        const SizedBox(height: DS.s16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Total', style: AppType.h3),
            Text(_money(order.totalAmount),
                style: AppType.h2.copyWith(color: DS.brandDeep)),
          ],
        ),
        const SizedBox(height: DS.s24),
        const _Label('UPDATE STATUS'),
        const SizedBox(height: DS.s12),
        Wrap(
          spacing: DS.s8,
          runSpacing: DS.s8,
          children: [
            for (final s in OrderStatus.assignable)
              ChoiceChip(
                label: Text(s.label),
                selected: _selectedStatus == s,
                onSelected: (_) => setState(() => _selectedStatus = s),
                selectedColor: s.color.withOpacity(0.18),
                backgroundColor: DS.surface,
                labelStyle: TextStyle(
                  color: _selectedStatus == s ? s.color : DS.inkSoft,
                  fontWeight: FontWeight.w600,
                ),
                side: BorderSide(
                    color: _selectedStatus == s ? s.color : DS.line),
              ),
          ],
        ),
        const SizedBox(height: DS.s8),
      ],
    );
  }
}

class _ItemsList extends ConsumerWidget {
  const _ItemsList({required this.orderId});
  final int orderId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(orderItemsProvider(orderId));
    return itemsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: DS.s16),
        child: Center(
            child: CircularProgressIndicator(color: DS.brand, strokeWidth: 2)),
      ),
      error: (e, _) => Text('Could not load items.',
          style: AppType.body.copyWith(color: DS.danger)),
      data: (items) {
        if (items.isEmpty) {
          return Text('No items on this order.', style: AppType.body);
        }
        return Container(
          decoration: BoxDecoration(
            color: DS.canvasAlt,
            borderRadius: BorderRadius.circular(DS.rMd),
            border: Border.all(color: DS.line),
          ),
          padding: const EdgeInsets.symmetric(horizontal: DS.s12, vertical: 2),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: DS.line),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: DS.s12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: DS.s8, vertical: 2),
                        decoration: BoxDecoration(
                          color: DS.surface,
                          borderRadius: BorderRadius.circular(DS.rSm),
                          border: Border.all(color: DS.line),
                        ),
                        child: Text('×${items[i].quantity}',
                            style: AppType.small.copyWith(
                                color: DS.ink, fontWeight: FontWeight.w700)),
                      ),
                      const SizedBox(width: DS.s12),
                      Expanded(
                          child: Text(items[i].itemName, style: AppType.body)),
                      Text(
                        items[i].lineTotal != null
                            ? '\u20B9${items[i].lineTotal!.toStringAsFixed(2)}'
                            : (items[i].itemPrice != null
                                ? '\u20B9${items[i].itemPrice!.toStringAsFixed(2)}'
                                : '—'),
                        style: AppType.bodyStrong,
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);
  final String text;
  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppType.eyebrow);
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.value);
  final IconData icon;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DS.s6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: DS.muted),
          const SizedBox(width: DS.s8),
          Expanded(child: Text(value, style: AppType.body)),
        ],
      ),
    );
  }
}
