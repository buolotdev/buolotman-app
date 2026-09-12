import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

/// Shared action sheet for non-profile attachments.
class AttachmentActions {
  static Future<void> show(
    BuildContext context, {
    required String label,
    required bool hasAttachment,
    required Future<void> Function() onDevice,
    required Future<void> Function() onGallery,
    required Future<void> Function() onCamera,
    required VoidCallback onRemove,
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
                leading: const Icon(Icons.folder_open_outlined),
                title: Text('Choose $label from device'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await onDevice();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined),
                title: Text('Choose $label from gallery'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await onGallery();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined),
                title: Text('Take $label with camera'),
                onTap: () async {
                  Navigator.pop(sheetContext);
                  await onCamera();
                },
              ),
              if (hasAttachment)
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

  static Future<PlatformFile?> pickGallery() async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
      maxWidth: 3000,
    );
    if (image == null) return null;
    final bytes = await image.readAsBytes();
    return PlatformFile(
      name: image.name,
      size: bytes.length,
      bytes: bytes,
      path: image.path,
    );
  }

  static Future<PlatformFile?> takePhoto(
    BuildContext context, {
    required String label,
  }) async {
    final image = await ImagePicker().pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
      maxWidth: 3000,
    );
    if (image == null) return null;
    final bytes = await image.readAsBytes();
    if (!context.mounted) return null;
    final usePhoto = await showDialog<bool>(
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
    if (usePhoto != true) return takePhoto(context, label: label);
    return PlatformFile(
      name: image.name,
      size: bytes.length,
      bytes: bytes,
      path: image.path,
    );
  }
}
