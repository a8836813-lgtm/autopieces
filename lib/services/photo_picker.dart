import 'package:image_picker/image_picker.dart';
import 'package:material_ui/material_ui.dart';

/// Lets the user take a photo or choose one from the gallery.
/// Returns the file path, or null when cancelled or when it failed.
class PhotoPicker {
  PhotoPicker._();

  static final ImagePicker _picker = ImagePicker();

  static Future<String?> pick(BuildContext context) async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(ctx).pop(ImageSource.gallery),
            ),
          ],
        ),
      ),
    );
    if (source == null) return null;
    try {
      final file = await _picker.pickImage(
        source: source,
        imageQuality: 70,
        maxWidth: 1600,
      );
      return file?.path;
    } catch (_) {
      return null;
    }
  }
}
