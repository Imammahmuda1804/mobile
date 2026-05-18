import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../app/config/env.dart';
import '../storage/secure_storage_service.dart';
import 'token_interceptor.dart';

final secureStorageProvider = Provider<SecureStorageService>((ref) {
  return const SecureStorageService(FlutterSecureStorage());
});

final dioProvider = Provider<Dio>((ref) {
  final dio = Dio(
    BaseOptions(
      baseUrl: Env.apiBaseUrl,
      connectTimeout: const Duration(seconds: 20),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(TokenInterceptor(ref, dio));
  return dio;
});

Map<String, dynamic> responseData(Response<dynamic> response) {
  final raw = response.data;
  if (raw is Map<String, dynamic>) return raw;
  return <String, dynamic>{};
}

dynamic unwrapData(Response<dynamic> response) {
  final map = responseData(response);
  return map['data'] ?? response.data;
}
