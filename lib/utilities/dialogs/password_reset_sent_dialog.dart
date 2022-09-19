import 'package:flutter/material.dart';
import 'package:mynotes/utilities/dialogs/generic_dialog.dart';

Future<void> showPasswordResetSentDialog(
  BuildContext context,
) {
  return showGenericDialog(
    context: context,
    title: 'Password Reset',
    content: 'We have sent a password reset link. Check Email',
    optionBuilder: () => {
      'OK': null,
    },
  );
}
