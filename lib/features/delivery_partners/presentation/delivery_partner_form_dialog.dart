import 'package:flutter/material.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialog.dart';
import '../data/delivery_partner_model.dart';

class DeliveryPartnerFormDialog extends StatefulWidget {
  const DeliveryPartnerFormDialog({super.key, this.existing});
  final DeliveryPartner? existing;

  @override
  State<DeliveryPartnerFormDialog> createState() =>
      _DeliveryPartnerFormDialogState();
}

class _DeliveryPartnerFormDialogState
    extends State<DeliveryPartnerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _vehicleNumber;
  String? _vehicleType;
  late bool _isActive;

  bool get _isEdit => widget.existing != null;

  static const _vehicleTypes = ['Bike', 'Scooter', 'Bicycle', 'Car', 'Van'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _phone = TextEditingController(text: e?.phone ?? '');
    _vehicleNumber = TextEditingController(text: e?.vehicleNumber ?? '');
    // Only preselect if the stored value is one of the known options.
    final t = e?.vehicleType?.trim();
    _vehicleType = (t != null && _vehicleTypes.contains(t)) ? t : null;
    _isActive = e?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _vehicleNumber.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final e = widget.existing;
    Navigator.of(context).pop(DeliveryPartner(
      id: e?.id,
      userId: e?.userId, // preserved; account linking handled elsewhere
      name: _name.text.trim(),
      phone: _phone.text.trim().isEmpty ? null : _phone.text.trim(),
      vehicleType: _vehicleType,
      vehicleNumber: _vehicleNumber.text.trim().isEmpty
          ? null
          : _vehicleNumber.text.trim(),
      isActive: _isActive,
      createdAt: e?.createdAt,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: AppDialog(
        title: _isEdit ? 'Edit partner' : 'Add delivery partner',
        actions: [
          AppButton(
              label: 'Cancel',
              variant: AppButtonVariant.ghost,
              onPressed: () => Navigator.of(context).pop()),
          AppButton(
              label: _isEdit ? 'Save changes' : 'Add', onPressed: _save),
        ],
        children: [
          DialogField(
            label: 'Name',
            child: TextFormField(
              controller: _name,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
          ),
          DialogField(
            label: 'Phone',
            child: TextFormField(
              controller: _phone,
              keyboardType: TextInputType.phone,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DialogField(
                  label: 'Vehicle type',
                  child: DropdownButtonFormField<String>(
                    value: _vehicleType,
                    isExpanded: true,
                    hint: const Text('Select'),
                    items: [
                      for (final t in _vehicleTypes)
                        DropdownMenuItem(value: t, child: Text(t)),
                    ],
                    onChanged: (v) => setState(() => _vehicleType = v),
                  ),
                ),
              ),
              const SizedBox(width: DS.s12),
              Expanded(
                child: DialogField(
                  label: 'Vehicle number',
                  child: TextFormField(controller: _vehicleNumber),
                ),
              ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeColor: DS.brand,
            title: const Text('Active'),
            value: _isActive,
            onChanged: (v) => setState(() => _isActive = v),
          ),
        ],
      ),
    );
  }
}
