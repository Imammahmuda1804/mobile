import 'package:dio/dio.dart';

import 'app_exception.dart';

AppException mapDioError(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    final message =
        data is Map<String, dynamic> ? data['message']?.toString() : null;

    return AppException(
      message ?? 'Koneksi bermasalah. Coba lagi beberapa saat.',
      statusCode: error.response?.statusCode,
    );
  }

  return const AppException('Terjadi kesalahan tidak terduga.');
}
