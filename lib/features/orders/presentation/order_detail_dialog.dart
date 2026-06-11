import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_theme.dart';
import '../data/order_model.dart';
import '../data/order_status.dart';
import 'order_controller.dart';
import 'status_chip.dart';

class OrderDetailDialog extends ConsumerStatefulWidget {
  const OrderDetailDialog({super.key, required this.order});

  final Order order;

  @override
  ConsumerState<OrderDetailDialog> createState() => _OrderDetailDialogState();
}

class _OrderDetailDialogState extends ConsumerState<OrderDetailDialog> {
  late OrderStatus _selectedStatus;
  bool _saving = false;

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
          backgroundColor: AppColors.positive,
        ));
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(
          content: Text(error),
          backgroundColor: AppColors.danger,
        ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = widget.order;
    final id = order.id;
    final dateText = order.createdAt == null
        ? null
        : DateFormat('d MMM yyyy, h:mm a').format(order.createdAt!.toLocal());

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      id == null ? 'Order' : 'Order #$id',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  StatusChip(status: order.status),
                ],
              ),
              if (dateText != null) ...[
                const SizedBox(height: 4),
                Text(dateText,
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
              const SizedBox(height: 20),
              _SectionLabel('CUSTOMER'),
              const SizedBox(height: 8),
              _InfoRow(Icons.person_outline, order.customerName),
              if (order.phone != null && order.phone!.isNotEmpty)
                _InfoRow(Icons.phone_outlined, order.phone!),
              if (order.address != null && order.address!.isNotEmpty)
                _InfoRow(Icons.location_on_outlined, order.address!),
              const SizedBox(height: 20),
              _SectionLabel('ITEMS'),
              const SizedBox(height: 8),
              if (id == null)
                Text('No order id — items unavailable.',
                    style: Theme.of(context).textTheme.bodyMedium)
              else
                _ItemsList(orderId: id),
              const SizedBox(height: 16),
              _TotalRow(amount: order.totalAmount),
              const SizedBox(height: 24),
              _SectionLabel('UPDATE STATUS'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final s in OrderStatus.assignable)
                    ChoiceChip(
                      label: Text(s.label),
                      selected: _selectedStatus == s,
                      onSelected: (_) => setState(() => _selectedStatus = s),
                      selectedColor: s.color.withOpacity(0.18),
                      labelStyle: TextStyle(
                        color: _selectedStatus == s ? s.color : AppColors.inkSoft,
                        fontWeight: FontWeight.w600,
                      ),
                      side: BorderSide(
                        color: _selectedStatus == s ? s.color : AppColors.line,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        _saving ? null : () => Navigator.of(context).pop(),
                    child: const Text('Close'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: (_saving || _selectedStatus == order.status)
                        ? null
                        : _saveStatus,
                    style: FilledButton.styleFrom(
                        minimumSize: const Size(150, 48)),
                    child: _saving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Save status'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
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
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Text(
        'Could not load items.',
        style: Theme.of(context)
            .textTheme
            .bodyMedium
            ?.copyWith(color: AppColors.danger),
      ),
      data: (items) {
        if (items.isEmpty) {
          return Text('No items on this order.',
              style: Theme.of(context).textTheme.bodyMedium);
        }
        return Container(
          decoration: BoxDecoration(
            color: AppColors.cream,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.line),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          child: Column(
            children: [
              for (var i = 0; i < items.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: AppColors.line),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.line),
                        ),
                        child: Text('×${items[i].quantity}',
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, fontSize: 13)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(items[i].itemName,
                            style: Theme.of(context).textTheme.bodyMedium),
                      ),
                      Text(
                        items[i].lineTotal != null
                            ? '₹${items[i].lineTotal!.toStringAsFixed(2)}'
                            : (items[i].itemPrice != null
                                ? '₹${items[i].itemPrice!.toStringAsFixed(2)}'
                                : '—'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
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

class _TotalRow extends StatelessWidget {
  const _TotalRow({this.amount});
  final double? amount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Total', style: Theme.of(context).textTheme.titleMedium),
        Text(
          amount != null ? '₹${amount!.toStringAsFixed(2)}' : '—',
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(color: AppColors.saffronDeep),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: Theme.of(context).textTheme.labelLarge);
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.icon, this.value);
  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.muted),
          const SizedBox(width: 10),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}
