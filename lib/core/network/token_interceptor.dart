import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/config/api_endpoints.dart';
import '../../features/auth/data/auth_controller.dart';
import 'dio_client.dart';

// Interceptor yang memasang access token dan menangani sesi kadaluarsa.
class TokenInterceptor extends Interceptor {
  TokenInterceptor(this.ref, this.dio);

  final Ref ref;
  final Dio dio;
  bool _isRefreshing = false;

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final storage = ref.read(secureStorageProvider);
    final token = await storage.readAccessToken();
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final isUnauthorized = err.response?.statusCode == 401;
    final alreadyRetried = err.requestOptions.extra['retried'] == true;

    if (!isUnauthorized || alreadyRetried || _isRefreshing) {
      handler.next(err);
      return;
    }

    _isRefreshing = true;
    try {
      final storage = ref.read(secureStorageProvider);
      final refreshToken = await storage.readRefreshToken();
      if (refreshToken == null) throw err;

      final refreshResponse = await dio.post<dynamic>(
        ApiEndpoints.refresh,
        data: {'refresh_token': refreshToken},
        options: Options(extra: {'skipAuthRefresh': true}),
      );

      final payload = unwrapData(refreshResponse) as Map<String, dynamic>;
      final accessToken = payload['access_token']?.toString();
      final newRefreshToken =
          payload['refresh_token']?.toString() ?? refreshToken;
      if (accessToken == null) throw err;

      await storage.saveTokens(
        accessToken: accessToken,
        refreshToken: newRefreshToken,
      );
      ref.read(authControllerProvider.notifier).markAuthenticated();

      final retryOptions = err.requestOptions;
      retryOptions.extra['retried'] = true;
      retryOptions.headers['Authorization'] = 'Bearer $accessToken';
      final retryResponse = await dio.fetch<dynamic>(retryOptions);
      handler.resolve(retryResponse);
    } catch (_) {
      await ref.read(authControllerProvider.notifier).logout();
      handler.next(err);
    } finally {
      _isRefreshing = false;
    }
  }
}
