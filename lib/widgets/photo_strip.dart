import 'dart:io';

import 'package:material_ui/material_ui.dart';

import '../theme.dart';

/// Row of small photo thumbnails with an optional "add" tile.
/// Tap a photo to see it full screen. Long press removes it (if [onRemove]).
class PhotoStrip extends StatelessWidget {
  final List<String> paths;
  final VoidCallback? onAdd;
  final void Function(String path)? onRemove;
  final double size;

  const PhotoStrip({
    super.key,
    required this.paths,
    this.onAdd,
    this.onRemove,
    this.size = 60,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final p in paths) _thumb(context, p),
        if (onAdd != null) _addTile(),
      ],
    );
  }

  Widget _thumb(BuildContext context, String path) {
    return GestureDetector(
      onTap: () => showDialog<void>(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(12),
          child: InteractiveViewer(
            child: Image.file(
              File(path),
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Padding(
                padding: EdgeInsets.all(40),
                child: Text('Photo not found',
                    style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
        ),
      ),
      onLongPress: onRemove == null
          ? null
          : () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Remove this photo?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(ctx).pop(false),
                      child: const Text('Keep'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.of(ctx).pop(true),
                      child: const Text('Remove'),
                    ),
                  ],
                ),
              );
              if (ok == true) onRemove!(path);
            },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: SizedBox(
          width: size,
          height: size,
          child: Image.file(
            File(path),
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: AppColors.chipBg,
              child: const Icon(Icons.broken_image_outlined,
                  color: AppColors.muted),
            ),
          ),
        ),
      ),
    );
  }

  Widget _addTile() {
    return InkWell(
      onTap: onAdd,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: const Icon(Icons.add_a_photo_outlined, color: AppColors.teal),
      ),
    );
  }
}
