import 'dart:async';

import 'package:flutter/foundation.dart';

import '../config/app_config.dart';
import '../data/repo.dart';
import 'api_client.dart';

/// The three account types. Each one has its own login and sign-up.
enum UserRole { client, mechanic, shop }

class AppUser {
  final String id;
  final String name;
  final String email;
  final String phone;
  final UserRole role;

  /// Role-specific data: garage name, shop name, wilaya, etc.
  final Map<String, String> profile;
  final String? shopId;
  final String? mechanicId;

  const AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    this.profile = const {},
    this.shopId,
    this.mechanicId,
  });
}

class AuthException implements Exception {
  final String message;
  const AuthException(this.message);
  @override
  String toString() => message;
}

class _Account {
  final AppUser user;
  final String password;
  const _Account(this.user, this.password);
}

/// PROTOTYPE auth service: everything lives in memory.
///
/// When the FastAPI backend exists, replace the bodies of [login] and
/// [signUp] with HTTP calls. The server must hash passwords (argon2/bcrypt),
/// return a short-lived JWT, and enforce the role on every endpoint.
/// The app must never decide permissions on its own.
class AuthService {
  AuthService._() {
    _seedDemoAccounts();
  }
  static final AuthService instance = AuthService._();

  final List<_Account> _accounts = [];
  final ValueNotifier<AppUser?> currentUser = ValueNotifier(null);
  int _nextId = 1;

  /// Demo credentials shown by the "Use demo account" button.
  static const Map<UserRole, (String, String)> demoCredentials = {
    UserRole.client: ('client@demo.dz', 'demo1234'),
    UserRole.mechanic: ('mechanic@demo.dz', 'demo1234'),
    UserRole.shop: ('shop@demo.dz', 'demo1234'),
  };

  void _seedDemoAccounts() {
    _add(UserRole.client, 'Demo Client', 'client@demo.dz', '0550000001',
        'demo1234', {'wilaya': 'Jijel'});
    _add(UserRole.mechanic, 'Demo Mechanic', 'mechanic@demo.dz', '0660000002',
        'demo1234', {
      'garage': 'Garage Demo',
      'specialty': 'General mechanics',
      'wilaya': 'Jijel',
      'experience': '8',
    });
    _add(UserRole.shop, 'Demo Owner', 'shop@demo.dz', '0770000003', 'demo1234', {
      'shopName': 'Pièces Auto Demo',
      'shopType': 'Retail shop',
      'address': 'Centre ville, Jijel',
      'wilaya': 'Jijel',
    });
  }

  AppUser _add(UserRole role, String name, String email, String phone,
      String password, Map<String, String> profile) {
    final user = AppUser(
      id: 'u${_nextId++}',
      name: name,
      email: email.trim().toLowerCase(),
      phone: phone,
      role: role,
      profile: profile,
    );
    _accounts.add(_Account(user, password));
    return user;
  }

  Future<AppUser> login({
    required UserRole role,
    required String email,
    required String password,
  }) async {
    if (AppConfig.useServer) {
      final data = await _remote(() => ApiClient.instance.post(
            ApiEndpoints.login,
            {'role': role.name, 'email': email.trim(), 'password': password},
          ));
      return _finishRemote(data);
    }
    await Future<void>.delayed(const Duration(milliseconds: 600));
    final e = email.trim().toLowerCase();

    final sameEmail = _accounts.where((a) => a.user.email == e).toList();
    if (sameEmail.isEmpty) {
      throw const AuthException('No account found with this email.');
    }
    final match = sameEmail.where((a) => a.user.role == role).toList();
    if (match.isEmpty) {
      // Same email exists but under another role: tell the user which one.
      throw AuthException(
          'This email is registered as a ${roleName(sameEmail.first.user.role)}. '
          'Go back and choose that role.');
    }
    if (match.first.password != password) {
      throw const AuthException('Incorrect password.');
    }
    currentUser.value = match.first.user;
    return match.first.user;
  }

  Future<AppUser> signUp({
    required UserRole role,
    required String name,
    required String email,
    required String phone,
    required String password,
    Map<String, String> profile = const {},
  }) async {
    if (AppConfig.useServer) {
      final created = await _remote(() => ApiClient.instance.post(
            ApiEndpoints.register,
            {
              'role': role.name,
              'name': name.trim(),
              'email': email.trim(),
              'phone': phone.trim(),
              'password': password,
              'profile': profile,
            },
          ));
      final me = await _remote(() async {
        ApiClient.instance.token = created['token'] as String;
        final r = await ApiClient.instance.get(ApiEndpoints.me);
        return {'token': created['token'], 'user': r['user']};
      });
      return _finishRemote(me);
    }
    await Future<void>.delayed(const Duration(milliseconds: 800));
    final e = email.trim().toLowerCase();
    if (_accounts.any((a) => a.user.email == e)) {
      throw const AuthException('An account with this email already exists.');
    }
    final user = _add(role, name.trim(), e, phone.trim(), password, profile);
    currentUser.value = user;
    return user;
  }

  void logout() {
    ApiClient.instance.token = null;
    Repo.instance.clearServerData();
    currentUser.value = null;
  }

  Future<Map<String, dynamic>> _remote(
      Future<Map<String, dynamic>> Function() call) async {
    try {
      return await call();
    } on ApiException catch (e) {
      throw AuthException(e.message);
    }
  }

  Future<AppUser> _finishRemote(Map<String, dynamic> data) async {
    ApiClient.instance.token = data['token'] as String;
    final u = data['user'] as Map<String, dynamic>;
    final profile = <String, String>{
      for (final e in ((u['profile'] as Map?) ?? const {}).entries)
        '${e.key}': '${e.value}',
    };
    final user = AppUser(
      id: '${u['id']}',
      name: u['name'] as String,
      email: u['email'] as String,
      phone: (u['phone'] as String?) ?? '',
      role: UserRole.values.byName(u['role'] as String),
      profile: profile,
      shopId: u['shop_id'] == null ? null : '${u['shop_id']}',
      mechanicId: u['mechanic_id'] == null ? null : '${u['mechanic_id']}',
    );
    try {
      await Repo.instance.loadFromServer(user);
    } on ApiException catch (e) {
      ApiClient.instance.token = null;
      throw AuthException(e.message);
    }
    currentUser.value = user;
    return user;
  }

  static String roleName(UserRole role) {
    switch (role) {
      case UserRole.client:
        return 'client';
      case UserRole.mechanic:
        return 'mechanic';
      case UserRole.shop:
        return 'shop owner';
    }
  }
}
