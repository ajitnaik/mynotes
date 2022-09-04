import 'package:flutter/material.dart';
import 'package:mynotes/utilities/dialogs/generic_dialog.dart';

Future<bool> showLogoutDialog(
  BuildContext context,
) {
  return showGenericDialog(
    context: context,
    title: 'Logout',
    content: 'Confirm Logout?',
    optionBuilder: () => {
      'Cancel': false,
      'OK': true,
    },
  ).then(
    (value) => value ?? false,
  );
}
