import 'package:flutter/material.dart';

/// Shows a simple yes/no confirmation dialog and returns `true` if the user
/// confirmed. Used for every destructive action (delete one capture, delete
/// all history) so nothing is ever removed without an explicit tap.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  required String confirmLabel,
  required String cancelLabel,
}) async {
  final bool? result = await showDialog<bool>(
    context: context,
    builder: (BuildContext context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actions: <Widget>[
        TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(cancelLabel)),
        FilledButton(onPressed: () => Navigator.of(context).pop(true), child: Text(confirmLabel)),
      ],
    ),
  );
  return result ?? false;
}
