import 'dart:math';

import 'package:mynotes/services/auth/auth_exceptions.dart';
import 'package:mynotes/services/auth/auth_provider.dart';
import 'package:mynotes/services/auth/auth_user.dart';
import 'package:test/test.dart';

void main() {
  group('Mock Authentication', (() {
    final provider = MockAuthProvider();
    
    test('Should not be initialized', (() {
      expect(provider._isInitialized, false);
    }));

    test('Cannot log out if not initialized', (() {
      expect(provider.logOut(), throwsA(const TypeMatcher<NotInitializedException>()));
    }));

    test('Should be able to be initialized', (() async {
      await provider.initialize();
      expect(provider._isInitialized, true);
    }));

    test('Create user should delegate to login', () async {
      final badEmailUser = provider.createUser(email: 'foo@bar.com', password: 'password');
      expect(badEmailUser, throwsA(const TypeMatcher<UserNotFoundAuthException>()));

      final badPassword = provider.createUser(email: 'zoo@bar.com', password: 'foobar');
      expect(badPassword, throwsA(const TypeMatcher<WrongPasswordAuthException>()));

      final user = await provider.createUser(email: 'foo', password: 'bar');
      expect(provider.currentUser, user);
      expect(user.isEmailVerified, false);
    });

    test('Should be able to verify Email', (() {
      provider.sendEmailVerification();
      final user = provider.currentUser;
      expect(user, isNotNull);
      expect(user!.isEmailVerified, true);
    }));

    test('Should be able to log out and log in again', () async {
      await provider.logOut();
      await provider.login(email: 'email', password: 'password');
      final user = provider.currentUser;

      expect(user, isNotNull);
    });
  }));
}

class NotInitializedException implements Exception {}

class MockAuthProvider implements AuthProvider {
  AuthUser? _user;
  var _isInitialized = false;
  bool get isInitialized => _isInitialized;

  @override
  Future<AuthUser> createUser(
      {required String email, required String password}) async {
    if (!isInitialized) throw NotInitializedException();
    await Future.delayed(const Duration(seconds: 2));
    return login(email: email, password: password);
  }

  @override
  // TODO: implement currentUser
  AuthUser? get currentUser => _user;

  @override
  Future<void> initialize() async {
    await Future.delayed(const Duration(seconds: 2));
    _isInitialized = true;
  }

  @override
  Future<void> logOut() async {
    if (!isInitialized) throw NotInitializedException();
    if (_user == null) throw UserNotFoundAuthException();
    await Future.delayed(const Duration(seconds: 1));
    _user = null;
  }

  @override
  Future<AuthUser> login({required String email, required String password}) {
    if (!isInitialized) throw NotInitializedException();
    if (email == 'foo@bar.com') throw UserNotFoundAuthException();
    if (password == 'foobar') throw WrongPasswordAuthException();
    const user = AuthUser(isEmailVerified: false, email: '', id: '');
    _user = user;
    return Future.value(user);
  }

  @override
  Future<void> sendEmailVerification() {
    if (!isInitialized) throw NotInitializedException();
    final user = _user;
    if (user == null) throw UserNotFoundAuthException();

    const newUser = AuthUser(isEmailVerified: true, email: '', id: '');
    _user = newUser;
    return Future.value();
  }
}
