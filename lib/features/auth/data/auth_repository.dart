import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/api_endpoints.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/network/dio_client.dart';
import 'auth_models.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(dioProvider));
});

// Repository API untuk login, register, dan user aktif.
class AuthRepository {
  const AuthRepository(this._dio);

  final Dio _dio;

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.login,
        data: {'email': email, 'password': password},
      );
      return AuthSession.fromJson(unwrapData(response) as Map<String, dynamic>);
    } catch (error) {
      throw mapDioError(error);
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      await _dio.post<dynamic>(
        ApiEndpoints.register,
        data: {'name': name, 'email': email, 'password': password},
      );
    } catch (error) {
      throw mapDioError(error);
    }
  }

  Future<AuthUser> fetchMe() async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.usersMe);
      return AuthUser.fromJson(unwrapData(response) as Map<String, dynamic>);
    } catch (error) {
      throw mapDioError(error);
    }
  }
}
