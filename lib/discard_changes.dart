import 'package:flutter/material.dart';

/// Shows the app's own discard dialog instead of a platform-default prompt.
Future<bool> confirmDiscardChanges(
  BuildContext context, {
  String title = 'Discard changes?',
  String message = 'You have unsaved changes. Leave without saving?',
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(dialogContext).pop(false),
          child: const Text('Keep editing'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Color(0xFFFF4500)),
          onPressed: () => Navigator.of(dialogContext).pop(true),
          child: const Text('Discard changes'),
        ),
      ],
    ),
  );
  return result == true;
}
