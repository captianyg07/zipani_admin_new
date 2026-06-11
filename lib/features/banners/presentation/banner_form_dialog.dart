import 'package:flutter/material.dart' hide Banner;

import '../../../core/theme/app_theme.dart';
import '../data/banner_model.dart';

/// Shared form for creating and editing a banner.
/// Returns a [Banner] via Navigator.pop on save, or null on cancel.
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
    // Rebuild preview as the URL changes.
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

    final result = Banner(
      id: e?.id,
      title: _title.text.trim(),
      subtitle:
          _subtitle.text.trim().isEmpty ? null : _subtitle.text.trim(),
      imageUrl: _imageUrl.text.trim(),
      isActive: _isActive,
    );

    Navigator.of(context).pop(result);
  }

  @override
  Widget build(BuildContext context) {
    final url = _imageUrl.text.trim();

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
                Text(_isEdit ? 'Edit banner' : 'Add banner',
                    style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 20),
                _Preview(url: url),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _title,
                  decoration: const InputDecoration(labelText: 'Title'),
                  textInputAction: TextInputAction.next,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Title is required'
                      : null,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _subtitle,
                  decoration: const InputDecoration(
                      labelText: 'Subtitle (optional)'),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _imageUrl,
                  decoration: const InputDecoration(labelText: 'Image URL'),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Image URL is required'
                      : null,
                ),
                const SizedBox(height: 8),
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

class _Preview extends StatelessWidget {
  const _Preview({required this.url});
  final String url;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        height: 140,
        width: double.infinity,
        color: AppColors.cream,
        child: url.isEmpty
            ? const Center(
                child: Icon(Icons.image_outlined,
                    color: AppColors.muted, size: 32),
              )
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Center(
                  child: Icon(Icons.broken_image_outlined,
                      color: AppColors.muted, size: 32),
                ),
                loadingBuilder: (context, child, progress) {
                  if (progress == null) return child;
                  return const Center(
                    child: SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  );
                },
              ),
      ),
    );
  }
}
