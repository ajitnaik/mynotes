import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:mynotes/constants/routes.dart';
import 'package:mynotes/services/auth/auth_exceptions.dart';
import 'package:mynotes/services/auth/auth_service.dart';
import 'package:mynotes/utilities/show_error_dialog.dart';

class RegisterView extends StatefulWidget {
  const RegisterView({Key? key}) : super(key: key);

  @override
  State<RegisterView> createState() => _RegisterViewState();
}

class _RegisterViewState extends State<RegisterView> {
  late final TextEditingController _email;
  late final TextEditingController _password;

  @override
  void initState() {
    _email = TextEditingController();
    _password = TextEditingController();

    super.initState();
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: Column(
        children: [
          TextField(
            controller: _email,
            enableSuggestions: false,
            autocorrect: false,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(hintText: 'Enter your email'),
          ),
          TextField(
            controller: _password,
            obscureText: true,
            enableSuggestions: false,
            autocorrect: false,
            decoration: const InputDecoration(hintText: 'Enter your password'),
          ),
          TextButton(
              onPressed: () async {
                final email = _email.text;
                final password = _password.text;

                try {
                  final userCredential = await AuthService.firebase()
                      .createUser(
                          email: email, password: password);

                  log(userCredential.toString());
                  await AuthService.firebase().sendEmailVerification();
                  if (!mounted) return;
                  Navigator.of(context).pushNamed(
                    verifyRoute,
                  );
                } on WeakPasswordAuthException catch (e) {
                  await showErrorDialog(context, 'Weak Password');
                } on EmailAlreadyInUseAuthException catch (e) {
                  showErrorDialog(context, 'Email is already in use');
                } on InvalidEmailAuthException catch (e) {
                  showErrorDialog(context, 'Invalid Email entered');
                } on GenericAuthException catch (e) {
                  await showErrorDialog(context, 'An Error Occurred');
                }
              },
              child: const Text('Register')),
          TextButton(
              onPressed: () {
                Navigator.of(context)
                    .pushNamedAndRemoveUntil(loginRoute, (route) => false);
              },
              child: const Text('Already Registered? Login here!'))
        ],
      ),
    );
  }
}
