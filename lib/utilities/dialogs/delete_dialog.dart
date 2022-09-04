import 'package:flutter/material.dart';
import 'package:mynotes/utilities/dialogs/generic_dialog.dart';

Future<bool> showDeleteDialog(
  BuildContext context,
) {
  return showGenericDialog(
    context: context,
    title: 'Delete',
    content: 'Confirm Delete?',
    optionBuilder: () => {
      'Cancel': false,
      'OK': true,
    },
  ).then(
    (value) => value ?? false,
  );
}