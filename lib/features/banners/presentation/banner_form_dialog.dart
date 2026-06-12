import 'package:flutter/material.dart' hide Banner;

import '../../../core/design/design_tokens.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_dialog.dart';
import '../data/banner_model.dart';

class BannerFormDialog extends StatefulWidget {
  const BannerFormDialog({super.key, this.existing});
  final Banner? existing;

  @override
  State<BannerFormDialog> createState() => _BannerFormDialogState();
}

class _BannerFormDialogState extends State<BannerFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _subtitle;
  late final TextEditingController _imageUrl;
  late bool _isActive;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _title = TextEditingController(text: e?.title ?? '');
    _subtitle = TextEditingController(text: e?.subtitle ?? '');
    _imageUrl = TextEditingController(text: e?.imageUrl ?? '');
    _isActive = e?.isActive ?? true;
    _imageUrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _title.dispose();
    _subtitle.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final e = widget.existing;
    Navigator.of(context).pop(Banner(
      id: e?.id,
      title: _title.text.trim(),
      subtitle: _subtitle.text.trim().isEmpty ? null : _subtitle.text.trim(),
      imageUrl: _imageUrl.text.trim(),
      isActive: _isActive,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final url = _imageUrl.text.trim();
    return Form(
      key: _formKey,
      child: AppDialog(
        title: _isEdit ? 'Edit campaign' : 'Create offer',
        actions: [
          AppButton(
              label: 'Cancel',
              variant: AppButtonVariant.ghost,
              onPressed: () => Navigator.of(context).pop()),
          AppButton(
              label: _isEdit ? 'Save changes' : 'Create', onPressed: _save),
        ],
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(DS.rMd),
            child: Container(
              height: 130,
              width: double.infinity,
              color: DS.canvasAlt,
              child: url.isEmpty
                  ? const Center(
                      child: Icon(Icons.image_outlined,
                          color: DS.muted, size: 30))
                  : Image.network(url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.broken_image_outlined,
                              color: DS.muted, size: 30))),
            ),
          ),
          const SizedBox(height: DS.s16),
          DialogField(
            label: 'Title',
            child: TextFormField(
              controller: _title,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Title is required' : null,
            ),
          ),
          DialogField(
            label: 'Subtitle',
            child: TextFormField(controller: _subtitle),
          ),
          DialogField(
            label: 'Image URL',
            child: TextFormField(
              controller: _imageUrl,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Image URL is required'
                  : null,
            ),
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
