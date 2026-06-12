import 'package:flutter/material.dart';

import '../../../core/design/design_tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialog.dart';
import '../data/restaurant_model.dart';

class RestaurantFormDialog extends StatefulWidget {
  const RestaurantFormDialog({super.key, this.existing});
  final Restaurant? existing;

  @override
  State<RestaurantFormDialog> createState() => _RestaurantFormDialogState();
}

class _RestaurantFormDialogState extends State<RestaurantFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _category;
  late final TextEditingController _rating;
  late final TextEditingController _deliveryTime;
  late final TextEditingController _imageUrl;
  late bool _isVeg;
  late bool _isActive;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _category = TextEditingController(text: e?.category ?? '');
    _rating = TextEditingController(text: e?.rating?.toString() ?? '');
    _deliveryTime = TextEditingController(text: e?.deliveryTime ?? '');
    _imageUrl = TextEditingController(text: e?.imageUrl ?? '');
    _isVeg = e?.isVeg ?? false;
    _isActive = e?.isActive ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _rating.dispose();
    _deliveryTime.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final r = widget.existing;
    final ratingText = _rating.text.trim();
    Navigator.of(context).pop(Restaurant(
      id: r?.id,
      name: _name.text.trim(),
      category: _category.text.trim().isEmpty ? null : _category.text.trim(),
      rating: ratingText.isEmpty ? null : double.tryParse(ratingText),
      deliveryTime:
          _deliveryTime.text.trim().isEmpty ? null : _deliveryTime.text.trim(),
      imageUrl: _imageUrl.text.trim().isEmpty ? null : _imageUrl.text.trim(),
      isVeg: _isVeg,
      isActive: _isActive,
      createdAt: r?.createdAt,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: AppDialog(
        title: _isEdit ? 'Edit restaurant' : 'Add restaurant',
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
            label: 'Category',
            child: TextFormField(controller: _category),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DialogField(
                  label: 'Rating (0–5)',
                  child: TextFormField(
                    controller: _rating,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      final t = v?.trim() ?? '';
                      if (t.isEmpty) return null;
                      final d = double.tryParse(t);
                      if (d == null) return 'Invalid';
                      if (d < 0 || d > 5) return '0–5 only';
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(width: DS.s12),
              Expanded(
                child: DialogField(
                  label: 'Delivery time',
                  child: TextFormField(controller: _deliveryTime),
                ),
              ),
            ],
          ),
          DialogField(
            label: 'Image URL',
            child: TextFormField(controller: _imageUrl),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeColor: DS.brand,
            title: const Text('Vegetarian'),
            value: _isVeg,
            onChanged: (v) => setState(() => _isVeg = v),
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
