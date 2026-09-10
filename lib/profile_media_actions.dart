import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Shared, platform-appropriate profile media actions.
/// Uploads remain the responsibility of the caller so each role can use its
/// existing API contract and verify persistence after saving.
class ProfileMediaActions {
  static Future<void> show(
    BuildContext context, {
    required String label,
    required bool hasImage,
    required VoidCallback onRemove,
    required VoidCallback onDefault,
    required Future<void> Function() onGallery,
    required Future<void> Function() onCamera,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: const Text('Choose from gallery'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await onGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: const Text('Take a photo'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await onCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.person_outline),
                title: Text('Use default $label silhouette'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  onDefault();
                },
              ),
              if (hasImage)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: Colors.red),
                  title: Text(
                    'Remove $label',
                    style: const TextStyle(color: Colors.red),
                  ),
                  onTap: () {
                    Navigator.pop(sheetContext);
                    onRemove();
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  static Future<XFile?> pick(
    BuildContext context, {
    required ImageSource source,
    required String label,
  }) async {
    final picker = ImagePicker();
    while (true) {
      final file = await picker.pickImage(
        source: source,
        imageQuality: 90,
        maxWidth: source == ImageSource.camera ? 2400 : 3000,
      );
      if (file == null) return null;
      if (source != ImageSource.camera) return file;

      final bytes = await file.readAsBytes();
      if (!context.mounted) return null;
      final decision = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: Text('Review $label'),
          content: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(bytes, height: 220, fit: BoxFit.cover),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Retake'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Use photo'),
            ),
          ],
        ),
      );
      if (decision == true) return file;
    }
  }

  static String? validate(XFile file, Uint8List bytes, String label) {
    final extension = file.name.toLowerCase().split('.').last;
    const supported = {'jpg', 'jpeg', 'png', 'webp', 'gif'};
    if (!supported.contains(extension)) {
      return '$label must be a JPG, PNG, WEBP, or GIF image.';
    }
    if (bytes.length > 25 * 1024 * 1024) {
      return '$label must be smaller than 25 MB.';
    }
    return null;
  }
}
