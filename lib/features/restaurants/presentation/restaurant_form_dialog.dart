import 'package:flutter/material.dart';

import '../../../core/theme/app_theme.dart';
import '../data/restaurant_model.dart';

/// Shared form for creating and editing a restaurant.
/// Returns a [Restaurant] via Navigator.pop on save, or null on cancel.
class RestaurantFormDialog extends StatefulWidget {
  const RestaurantFormDialog({super.key, this.existing});

  /// When non-null, the dialog is in edit mode.
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

    final ratingText = _rating.text.trim();
    final base = widget.existing;

    final result = Restaurant(
      id: base?.id,
      name: _name.text.trim(),
      category: _category.text.trim().isEmpty ? null : _category.text.trim(),
      rating: ratingText.isEmpty ? null : double.tryParse(ratingText),
      deliveryTime:
          _deliveryTime.text.trim().isEmpty ? null : _deliveryTime.text.trim(),
      imageUrl: _imageUrl.text.trim().isEmpty ? null : _imageUrl.text.trim(),
      isVeg: _isVeg,
      isActive: _isActive,
      createdAt: base?.createdAt,
    );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
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
                Text(_isEdit ? 'Edit restaurant' : 'Add restaurant',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _name,
                  decoration: const InputDecoration(labelText: 'Name'),
                  textInputAction: TextInputAction.next,
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _category,
                  decoration:
                      const InputDecoration(labelText: 'Category (optional)'),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _rating,
                        decoration:
                            const InputDecoration(labelText: 'Rating (0–5)'),
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        validator: (v) {
                          final t = v?.trim() ?? '';
                          if (t.isEmpty) return null; // optional
                          final d = double.tryParse(t);
                          if (d == null) return 'Invalid number';
                          if (d < 0 || d > 5) return '0–5 only';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _deliveryTime,
                        decoration: const InputDecoration(
                            labelText: 'Delivery time'),
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
                  title: const Text('Active'),
                  value: _isActive,
                  onChanged: (v) => setState(() => _isActive = v),
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
                        minimumSize: const Size(120, 48),
                      ),
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
