import 'package:flutter/material.dart';
import 'package:mynotes/utilities/dialogs/generic_dialog.dart';

Future<void> showCannotShareEmptyDialog(
  BuildContext context,
) {
  return showGenericDialog(
    context: context,
    title: 'Sharing',
    content: 'Cannot share empty dialog',
    optionBuilder: () => {
      'OK': null,
    },
  );
}