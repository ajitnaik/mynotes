import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter/src/foundation/key.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mynotes/services/auth/bloc/auth_bloc.dart';
import 'package:mynotes/services/auth/bloc/auth_event.dart';
import 'package:mynotes/services/auth/bloc/auth_state.dart';
import 'package:mynotes/utilities/dialogs/error_dialog.dart';
import 'package:mynotes/utilities/dialogs/password_reset_sent_dialog.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  late final TextEditingController _textEditingController;

  @override
  void initState() {
    _textEditingController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
        listener: ((context, state) async {
          if (state is AuthStateForgotPassword) {
            if (state.hasSentEmail) {
              _textEditingController.clear();
              await showPasswordResetSentDialog(context);
            } else if (state.exception != null) {
              await showErrorDialog(context, 'Could not process your request');
              log(state.exception.toString());
            }
          }
        }),
        child: Scaffold(
          appBar: AppBar(title: const Text('Forgot Password')),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(children: [
              const Text(
                  'Enter your email. We will send you password reset link'),
              TextField(
                controller: _textEditingController,
                enableSuggestions: false,
                autocorrect: false,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(hintText: 'Enter your email'),
              ),
              TextButton(
                  onPressed: () {
                    final email = _textEditingController.text;
                    context.read<AuthBloc>().add(AuthEventForgotPassword(email));
                  },
                  child: const Text('Send password reset link')),
              TextButton(
                  onPressed: () {
                    context.read<AuthBloc>().add(const AuthEventLogout());
                  }, child: const Text('Back to Login page'))
            ]),
          ),
        ));
  }
}
