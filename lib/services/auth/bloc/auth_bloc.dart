import 'dart:developer';

import 'package:bloc/bloc.dart';
import 'package:mynotes/services/auth/auth_provider.dart';
import 'package:mynotes/services/auth/bloc/auth_event.dart';
import 'package:mynotes/services/auth/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(AuthProvider authProvider)
      : super(const AuthStateUnitialized(isLoading: true)) {
    on<AuthEventSendEmailVerification>((event, emit) async {
      await authProvider.sendEmailVerification();
      emit(state);
    });

    on<AuthEventShouldRegister>((event, emit) async {
      emit(const AuthStateRegistering(isLoading: false, exception: null));
    });

    on<AuthEventRegister>((event, emit) async {
      final email = event.email;
      final password = event.password;

      try {
        await authProvider.createUser(
          email: email,
          password: password,
        );
        await authProvider.sendEmailVerification();
        emit(const AuthStateNeedsVerification(isLoading: false));
      } on Exception catch (e) {
        emit(AuthStateRegistering(isLoading: false, exception: e));
      }
    });

    on<AuthEventInitialize>((event, emit) async {
      await authProvider.initialize();
      final user = authProvider.currentUser;

      if (user == null) {
        emit(const AuthStateLoggedOut(
          exception: null,
          isLoading: false,
        ));
      } else if (!user.isEmailVerified) {
        emit(const AuthStateNeedsVerification(isLoading: false));
      } else {
        emit(AuthStateLoggedIn(
          user: user,
          isLoading: false,
        ));
      }
    });

    on<AuthEventLogin>((event, emit) async {
      emit(
        const AuthStateLoggedOut(
          exception: null,
          isLoading: true,
          loadingText: 'Please wait while you are logged in',
        ),
      );
      final email = event.email;
      final password = event.password;
      try {
        final user = await authProvider.login(
          email: email,
          password: password,
        );

        if (!user.isEmailVerified) {
          emit(
            const AuthStateLoggedOut(
              exception: null,
              isLoading: false,
            ),
          );
          emit(const AuthStateNeedsVerification(isLoading: false));
        } else {
          emit(const AuthStateLoggedOut(
            exception: null,
            isLoading: false,
          ));
          emit(AuthStateLoggedIn(
            user: user,
            isLoading: false,
          ));
        }
      } on Exception catch (e) {
        emit(
          AuthStateLoggedOut(
            exception: e,
            isLoading: false,
          ),
        );
      }
    });

    on<AuthEventLogout>((event, emit) async {
      emit(const AuthStateUnitialized(isLoading: true));
      try {
        await authProvider.logOut();
        emit(const AuthStateLoggedOut(exception: null, isLoading: false));
      } on Exception catch (e) {
        emit(AuthStateLoggedOut(exception: e, isLoading: false));
      }
    });

    on<AuthEventForgotPassword>(
      (event, emit) async {
        try {
          emit(const AuthStateForgotPassword(exception: null, hasSentEmail: false, isLoading: false));
          final email = event.email;
          
          if (email == null) {
            return;
          } else {
            emit(const AuthStateForgotPassword(exception: null, hasSentEmail: false, isLoading: true));
            await authProvider.sendPasswordReset(email: email);
            emit(const AuthStateForgotPassword(exception: null, hasSentEmail: true, isLoading: false));
          }
        } on Exception catch (e) {
          emit(AuthStateForgotPassword(exception: e, hasSentEmail: false, isLoading: false));
        }
      },
    );
  }
}
