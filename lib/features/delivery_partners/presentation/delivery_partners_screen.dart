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
import '../data/delivery_partner_model.dart';
import '../data/delivery_partner_repository.dart';
import 'delivery_partner_controller.dart';
import 'delivery_partner_form_dialog.dart';

class DeliveryPartnersScreen extends ConsumerStatefulWidget {
  const DeliveryPartnersScreen({super.key});

  @override
  ConsumerState<DeliveryPartnersScreen> createState() =>
      _DeliveryPartnersScreenState();
}

class _DeliveryPartnersScreenState
    extends ConsumerState<DeliveryPartnersScreen> {
  final _search = TextEditingController();
  Timer? _debounce;

  static const _filterValues = [
    PartnerActiveFilter.all,
    PartnerActiveFilter.active,
    PartnerActiveFilter.inactive,
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
        () => ref.read(deliveryPartnerControllerProvider.notifier).setSearch(v));
  }

  void _snack(String m, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
          content: Text(m),
          backgroundColor: error ? DS.danger : DS.success));
  }

  Future<void> _openForm({DeliveryPartner? existing}) async {
    final result = await showDialog<DeliveryPartner>(
      context: context,
      builder: (_) => DeliveryPartnerFormDialog(existing: existing),
    );
    if (result == null) return;
    final n = ref.read(deliveryPartnerControllerProvider.notifier);
    final err =
        existing == null ? await n.create(result) : await n.update(result);
    _snack(err ?? (existing == null ? 'Partner added' : 'Changes saved'),
        error: err != null);
  }

  Future<void> _confirmDelete(DeliveryPartner p) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete partner'),
        content: Text('Delete "${p.name}"? This cannot be undone.'),
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
    if (ok != true || p.id == null) return;
    final err =
        await ref.read(deliveryPartnerControllerProvider.notifier).delete(p.id!);
    _snack(err ?? 'Partner deleted', error: err != null);
  }

  Future<void> _toggle(DeliveryPartner p) async {
    final err = await ref
        .read(deliveryPartnerControllerProvider.notifier)
        .toggleActive(p);
    _snack(err ?? (p.isActive ? 'Deactivated' : 'Activated'),
        error: err != null);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(deliveryPartnerControllerProvider);
    final n = ref.read(deliveryPartnerControllerProvider.notifier);

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
                      hint: 'Search by name or phone',
                      width: 320),
                  const Spacer(),
                  AppButton(
                      label: 'Add partner',
                      icon: Icons.add,
                      onPressed: () => _openForm()),
                ],
              ),
              const SizedBox(height: DS.s16),
              SegmentedTabs<PartnerActiveFilter>(
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
                    title: 'Could not load partners',
                    message: state.error!,
                    onRetry: n.load)
              else if (state.items.isEmpty)
                const EmptyState(
                    icon: Icons.delivery_dining_outlined,
                    title: 'No delivery partners found',
                    message: 'Add your first delivery partner to get started.')
              else
                ModernDataTable(
                  columns: const [
                    TableColumn('Partner', flex: 3),
                    TableColumn('Phone', flex: 2),
                    TableColumn('Vehicle', flex: 2),
                    TableColumn('Status', flex: 1),
                    TableColumn('', fixed: 48),
                  ],
                  footer: _Pager(state: state, notifier: n),
                  rows: [
                    for (final p in state.items)
                      TableRowData(cells: [
                        Row(
                          children: [
                            AppAvatar(
                                label: p.name, size: 38, background: DS.info),
                            const SizedBox(width: DS.s12),
                            Expanded(
                              child: Text(p.name,
                                  style: AppType.bodyStrong,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                        Text(p.phone ?? '—', style: AppType.body),
                        Text(_vehicleLabel(p), style: AppType.body),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: StatusPill.toggle(on: p.isActive),
                        ),
                        _RowMenu(
                          isActive: p.isActive,
                          onEdit: () => _openForm(existing: p),
                          onToggle: () => _toggle(p),
                          onDelete: () => _confirmDelete(p),
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

  String _vehicleLabel(DeliveryPartner p) {
    final type = p.vehicleType?.trim() ?? '';
    final number = p.vehicleNumber?.trim() ?? '';
    if (type.isEmpty && number.isEmpty) return '—';
    if (number.isEmpty) return type;
    if (type.isEmpty) return number;
    return '$type · $number';
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
  final DeliveryPartnerListState state;
  final DeliveryPartnerController notifier;

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
