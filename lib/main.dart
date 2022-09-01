import 'dart:developer';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:mynotes/constants/routes.dart';
import 'package:mynotes/firebase_options.dart';
import 'package:mynotes/view/login_view.dart';
import 'package:mynotes/view/register_view.dart';
import 'package:mynotes/view/verify_email_view.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MaterialApp(
    title: 'Flutter Demo',
    theme: ThemeData(
      primarySwatch: Colors.blue,
    ),
    home: const HomePage(),
    routes: {
      loginRoute: (context) => const LoginView(),
      registerRoute: (context) => const RegisterView(),
      notesRoute: ((context) => const NotesView()),
      verifyRoute:(context) => const VerifyEmailView(),
    },
  ));
}

class HomePage extends StatelessWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform),
      builder: (BuildContext context, AsyncSnapshot<dynamic> snapshot) {
        switch (snapshot.connectionState) {
          case ConnectionState.done:
            final user = FirebaseAuth.instance.currentUser;

            if (user != null) {
              if (user.emailVerified) {
                print('Email verified');
              } else {
                print('Email not verified $user');
                return const VerifyEmailView();
              }
            } else {
              return const LoginView();
            }
            // if (user?.emailVerified ?? false) {
            //   print('Email verified');
            // } else {
            //   print('Email not verified $user');
            //   Navigator.of(context).push(MaterialPageRoute(
            //       builder: (context) => const VerifyEmailView()));
            // }
            return const NotesView();

          default:
            return const Text('Loading');
        }
      },
    );
  }
}

enum MenuAction { logout }

class NotesView extends StatefulWidget {
  const NotesView({Key? key}) : super(key: key);

  @override
  State<NotesView> createState() => _NotesViewState();
}

class _NotesViewState extends State<NotesView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Main UI'),
        actions: [
          PopupMenuButton<MenuAction>(
            itemBuilder: ((context) {
              return const [
                PopupMenuItem<MenuAction>(
                  value: MenuAction.logout,
                  child: Text('Log out'),
                )
              ];
            }),
            onSelected: (value) async {
              switch (value) {
                case MenuAction.logout:
                  final shouldLogout = await showLogoutDialog(context);
                  log(shouldLogout.toString());
                  if (shouldLogout) {
                    await FirebaseAuth.instance.signOut();

                    if (!mounted) return;
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil(loginRoute, (_) => false);
                  }
                  break;
              }
            },
          )
        ],
      ),
      body: const Text('Hello World'),
    );
  }
}

Future<bool> showLogoutDialog(BuildContext context) {
  return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Sign out'),
          content: const Text('Are you sure?'),
          actions: [
            TextButton(
                onPressed: (() {
                  Navigator.of(context).pop(false);
                }),
                child: const Text('Cancel')),
            TextButton(
                onPressed: (() {
                  Navigator.of(context).pop(true);
                }),
                child: const Text('Logout'))
          ],
        );
      }).then((value) => value ?? false);
}
