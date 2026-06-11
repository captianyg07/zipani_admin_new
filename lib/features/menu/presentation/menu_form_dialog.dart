import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/menu_item_model.dart';

/// Shared form for creating and editing a menu item.
/// Returns a [MenuItem] via Navigator.pop on save, or null on cancel.
///
/// Role behavior:
/// - Super admin: [isOwner] is false; the restaurant dropdown is shown and
///   any restaurant in [restaurantNames] may be chosen.
/// - Restaurant owner: [isOwner] is true and [lockedRestaurantId] is their
///   own restaurant. The dropdown is hidden, the restaurant is auto-assigned
///   and shown as read-only text, and it cannot be changed.
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
    // Owners are locked to their own restaurant regardless of the item's
    // stored value (defense in depth against a tampered/legacy row).
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

    // Owners always write their own restaurant id; admins use the picked one.
    final restaurantId =
        widget.isOwner ? widget.lockedRestaurantId : _restaurantId;
    if (restaurantId == null) return; // guarded by validator too

    final priceText = _price.text.trim();
    final e = widget.existing;

    final result = MenuItem(
      id: e?.id,
      restaurantId: restaurantId,
      name: _name.text.trim(),
      category: _category.text.trim().isEmpty ? null : _category.text.trim(),
      price: priceText.isEmpty ? null : double.tryParse(priceText),
      imageUrl: _imageUrl.text.trim().isEmpty ? null : _imageUrl.text.trim(),
      isVeg: _isVeg,
      isAvailable: _isAvailable,
    );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    // Stable, name-sorted dropdown entries.
    final entries = widget.restaurantNames.entries.toList()
      ..sort((a, b) => a.value.toLowerCase().compareTo(b.value.toLowerCase()));

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 460),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_isEdit ? 'Edit menu item' : 'Add menu item',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 20),
                if (widget.isOwner)
                  _OwnerRestaurantField(
                    name: widget.restaurantNames[_restaurantId] ??
                        'Your restaurant',
                  )
                else
                  DropdownButtonFormField<int>(
                    value: _restaurantId,
                    isExpanded: true,
                    decoration:
                        const InputDecoration(labelText: 'Restaurant'),
                    items: [
                      for (final e in entries)
                        DropdownMenuItem(
                          value: e.key,
                          child:
                              Text(e.value, overflow: TextOverflow.ellipsis),
                        ),
                    ],
                    onChanged: (v) => setState(() => _restaurantId = v),
                    validator: (v) =>
                        v == null ? 'Select a restaurant' : null,
                  ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Item name'),
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Name is required'
                      : null,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _category,
                        decoration: const InputDecoration(
                            labelText: 'Category (optional)'),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _price,
                        decoration: const InputDecoration(labelText: 'Price'),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (v) {
                          final t = v?.trim() ?? '';
                          if (t.isEmpty) return null; // optional
                          final d = double.tryParse(t);
                          if (d == null) return 'Invalid number';
                          if (d < 0) return 'Must be ≥ 0';
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _imageUrl,
                  decoration:
                      const InputDecoration(labelText: 'Image URL (optional)'),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.saffron,
                  title: const Text('Vegetarian'),
                  value: _isVeg,
                  onChanged: (v) => setState(() => _isVeg = v),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  activeColor: AppColors.saffron,
                  title: const Text('Available'),
                  value: _isAvailable,
                  onChanged: (v) => setState(() => _isAvailable = v),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      onPressed: _save,
                      style: FilledButton.styleFrom(
                          minimumSize: const Size(120, 48)),
                      child: Text(_isEdit ? 'Save changes' : 'Add'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Read-only restaurant display shown to restaurant owners in place of the
/// dropdown. The owner cannot change the restaurant.
class _OwnerRestaurantField extends StatelessWidget {
  const _OwnerRestaurantField({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.line),
      ),
      child: Row(
        children: [
          const Icon(Icons.storefront_outlined,
              size: 18, color: AppColors.muted),
          const SizedBox(width: 10),
          Text('Restaurant: ',
              style: Theme.of(context).textTheme.bodyMedium),
          Expanded(
            child: Text(
              name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
