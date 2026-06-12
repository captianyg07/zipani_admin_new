import 'package:flutter/material.dart' hide MenuController;

import '../../../core/design/design_tokens.dart';
import '../../../core/design/typography.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialog.dart';
import '../data/menu_item_model.dart';

class MenuFormDialog extends StatefulWidget {
  const MenuFormDialog({
    super.key,
    required this.restaurantNames,
    this.existing,
    this.isOwner = false,
    this.lockedRestaurantId,
  });

  final Map<int, String> restaurantNames;
  final MenuItem? existing;
  final bool isOwner;
  final int? lockedRestaurantId;

  @override
  State<MenuFormDialog> createState() => _MenuFormDialogState();
}

class _MenuFormDialogState extends State<MenuFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _category;
  late final TextEditingController _price;
  late final TextEditingController _imageUrl;
  int? _restaurantId;
  late bool _isVeg;
  late bool _isAvailable;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _category = TextEditingController(text: e?.category ?? '');
    _price = TextEditingController(text: e?.price?.toString() ?? '');
    _imageUrl = TextEditingController(text: e?.imageUrl ?? '');
    _restaurantId = e?.restaurantId;
    if (widget.isOwner && widget.lockedRestaurantId != null) {
      _restaurantId = widget.lockedRestaurantId;
    }
    _isVeg = e?.isVeg ?? false;
    _isAvailable = e?.isAvailable ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _category.dispose();
    _price.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final restaurantId =
        widget.isOwner ? widget.lockedRestaurantId : _restaurantId;
    if (restaurantId == null) return;
    final priceText = _price.text.trim();
    final e = widget.existing;
    Navigator.of(context).pop(MenuItem(
      id: e?.id,
      restaurantId: restaurantId,
      name: _name.text.trim(),
      category: _category.text.trim().isEmpty ? null : _category.text.trim(),
      price: priceText.isEmpty ? null : double.tryParse(priceText),
      imageUrl: _imageUrl.text.trim().isEmpty ? null : _imageUrl.text.trim(),
      isVeg: _isVeg,
      isAvailable: _isAvailable,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.restaurantNames.entries.toList()
      ..sort((a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()));

    return Form(
      key: _formKey,
      child: AppDialog(
        title: _isEdit ? 'Edit menu item' : 'Add menu item',
        actions: [
          AppButton(
              label: 'Cancel',
              variant: AppButtonVariant.ghost,
              onPressed: () => Navigator.of(context).pop()),
          AppButton(
              label: _isEdit ? 'Save changes' : 'Add', onPressed: _save),
        ],
        children: [
          if (widget.isOwner)
            _OwnerRestaurantField(
              name: widget.restaurantNames[_restaurantId] ?? 'Your restaurant',
            )
          else
            DialogField(
              label: 'Restaurant',
              child: DropdownButtonFormField<int>(
                value: _restaurantId,
                isExpanded: true,
                items: [
                  for (final e in entries)
                    DropdownMenuItem(
                        value: e.key,
                        child:
                            Text(e.value, overflow: TextOverflow.ellipsis)),
                ],
                onChanged: (v) => setState(() => _restaurantId = v),
                validator: (v) => v == null ? 'Select a restaurant' : null,
              ),
            ),
          DialogField(
            label: 'Item name',
            child: TextFormField(
              controller: _name,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Name is required' : null,
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: DialogField(
                  label: 'Category',
                  child: TextFormField(controller: _category),
                ),
              ),
              const SizedBox(width: DS.s12),
              Expanded(
                child: DialogField(
                  label: 'Price',
                  child: TextFormField(
                    controller: _price,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    validator: (v) {
                      final t = v?.trim() ?? '';
                      if (t.isEmpty) return null;
                      final d = double.tryParse(t);
                      if (d == null) return 'Invalid';
                      if (d < 0) return '≥ 0';
                      return null;
                    },
                  ),
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
            title: const Text('Available'),
            value: _isAvailable,
            onChanged: (v) => setState(() => _isAvailable = v),
          ),
        ],
      ),
    );
  }
}

class _OwnerRestaurantField extends StatelessWidget {
  const _OwnerRestaurantField({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: DS.s16),
      child: Container(
        width: double.infinity,
        padding:
            const EdgeInsets.symmetric(horizontal: DS.s16, vertical: DS.s12),
        decoration: BoxDecoration(
          color: DS.canvasAlt,
          borderRadius: BorderRadius.circular(DS.rMd),
          border: Border.all(color: DS.line),
        ),
        child: Row(
          children: [
            const Icon(Icons.storefront_outlined, size: 18, color: DS.muted),
            const SizedBox(width: DS.s8),
            Text('Restaurant: ', style: AppType.body),
            Expanded(
              child: Text(name,
                  overflow: TextOverflow.ellipsis, style: AppType.bodyStrong),
            ),
          ],
        ),
      ),
    );
  }
}
