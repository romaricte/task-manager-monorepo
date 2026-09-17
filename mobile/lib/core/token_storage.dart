import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/user.dart';

class TokenStorage {
  TokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  static const _tokenKey = 'momentum_jwt';
  static const _userKey = 'momentum_user';

  final FlutterSecureStorage _storage;

  Future<void> saveSession({
    required String token,
    required AppUser user,
  }) async {
    await Future.wait([
      _storage.write(key: _tokenKey, value: token),
      _storage.write(key: _userKey, value: jsonEncode(user.toJson())),
    ]);
  }

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<AppUser?> readUser() async {
    final rawUser = await _storage.read(key: _userKey);
    if (rawUser == null) return null;
    try {
      return AppUser.fromJson(jsonDecode(rawUser) as Map<String, dynamic>);
    } on FormatException {
      await clear();
      return null;
    }
  }

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(key: _tokenKey),
      _storage.delete(key: _userKey),
    ]);
  }
}
