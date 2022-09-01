import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mynotes/constants/routes.dart';

class VerifyEmailView extends StatefulWidget {
  const VerifyEmailView({Key? key}) : super(key: key);

  @override
  State<VerifyEmailView> createState() => _VerifyEmailViewState();
}

class _VerifyEmailViewState extends State<VerifyEmailView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: Column(
        children: [
          const Text(
              'We have sent you a verification Email. Please Verify your Email'),
          TextButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              await user?.sendEmailVerification();
            },
            child: const Text('Resend Email Verification'),
          ),
          TextButton(
            onPressed: (() async {
              await FirebaseAuth.instance.signOut();
              if (!mounted) {
                return;
              }
              Navigator.of(context).pushNamedAndRemoveUntil(registerRoute, (route) => false);
            }),
            child: const Text('Restart'),
          )
        ],
      ),
    );
  }
}
