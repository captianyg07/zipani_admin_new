import 'package:flutter/material.dart';

import '../../../core/widgets/status_pill.dart';
import '../data/order_status.dart';

/// Back-compat wrapper. Status display now goes through the shared StatusPill;
/// this remains so any lingering references keep working.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});
  final OrderStatus status;

  @override
  Widget build(BuildContext context) =>
      StatusPill(label: status.label, color: status.color);
}
