import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/config/api_endpoints.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/network/dio_client.dart';
import '../../auth/data/auth_models.dart';
import 'profile_models.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  return ProfileRepository(ref.read(dioProvider));
});

class ProfileRepository {
  const ProfileRepository(this._dio);

  final Dio _dio;

  Future<AuthUser> fetchMe() async {
    final response = await _dio.get<dynamic>(ApiEndpoints.usersMe);
    return AuthUser.fromJson(unwrapData(response) as Map<String, dynamic>);
  }

  Future<AuthUser> updateProfile({
    required String name,
    required String email,
    String? password,
  }) async {
    final response = await _dio.put<dynamic>(
      ApiEndpoints.usersMe,
      data: {
        'name': name,
        'email': email,
        if (password != null && password.isNotEmpty) 'password': password,
      },
    );
    return AuthUser.fromJson(unwrapData(response) as Map<String, dynamic>);
  }

  Future<AuthUser> uploadAvatar(XFile image) async {
    final response = await _dio.post<dynamic>(
      ApiEndpoints.usersMeAvatar,
      data: FormData.fromMap({
        'file': await MultipartFile.fromFile(
          image.path,
          filename: image.name,
        ),
      }),
    );
    return AuthUser.fromJson(unwrapData(response) as Map<String, dynamic>);
  }

  Future<List<FavoriteDestination>> fetchFavorites() async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.favorites,
        queryParameters: {'limit': 50},
      );
      final data = unwrapData(response);
      final list = data is List
          ? data
          : data is Map<String, dynamic> && data['data'] is List
              ? data['data'] as List
              : const [];
      return list
          .whereType<Map<String, dynamic>>()
          .map((item) {
            try {
              return FavoriteDestination.fromJson(item);
            } on FormatException {
              return null;
            }
          })
          .whereType<FavoriteDestination>()
          .toList();
    } catch (error) {
      throw mapDioError(error);
    }
  }

  Future<void> removeFavorite(int destinationId) {
    return _dio.delete<dynamic>(
      ApiEndpoints.favoriteByDestination(destinationId),
    );
  }

  Future<void> addFavorite(int destinationId) {
    return _dio.post<dynamic>(
      ApiEndpoints.favoriteByDestination(destinationId),
    );
  }
}
