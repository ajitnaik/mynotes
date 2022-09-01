import 'package:mynotes/services/auth/auth_user.dart';

abstract class AuthProvider {
  AuthUser? get currentUser;
  Future<AuthUser> login({required String email, required String password,})
}