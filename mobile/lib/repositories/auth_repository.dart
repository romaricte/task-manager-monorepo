import '../core/api_client.dart';
import '../core/token_storage.dart';
import '../models/user.dart';

class AuthRepository {
  const AuthRepository(this._apiClient, this._storage);

  final ApiClient _apiClient;
  final TokenStorage _storage;

  Future<AppUser> login({required String email, required String password}) {
    return _authenticate('/api/auth/login', {
      'email': email.trim(),
      'password': password,
    });
  }

  Future<AppUser> register({
    required String name,
    required String email,
    required String password,
  }) {
    return _authenticate('/api/auth/register', {
      'name': name.trim(),
      'email': email.trim(),
      'password': password,
    });
  }

  Future<AppUser> _authenticate(
    String path,
    Map<String, dynamic> payload,
  ) async {
    try {
      final response = await _apiClient.dio.post<Map<String, dynamic>>(
        path,
        data: payload,
      );
      final data = response.data!;
      final user = AppUser.fromJson(data['user'] as Map<String, dynamic>);
      await _storage.saveSession(token: data['token'] as String, user: user);
      return user;
    } catch (error) {
      throw _apiClient.mapError(error);
    }
  }

  Future<AppUser?> restoreSession() async {
    final token = await _storage.readToken();
    if (token == null || token.isEmpty) return null;
    return _storage.readUser();
  }

  Future<void> logout() => _storage.clear();
}
