import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/api_endpoints.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/network/dio_client.dart';
import 'route_models.dart';

final routesRepositoryProvider = Provider<RoutesRepository>((ref) {
  return RoutesRepository(ref.read(dioProvider));
});

class RoutesRepository {
  const RoutesRepository(this._dio);

  final Dio _dio;

  Future<List<TravelRoute>> fetchPublicRoutes() async {
    final response = await _dio.get<dynamic>(
      ApiEndpoints.routesPublic,
      queryParameters: const {'limit': 30},
    );
    return _readList(response).map(TravelRoute.fromJson).toList();
  }

  Future<List<TravelRoute>> fetchMyRoutes() async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.routesMine,
        queryParameters: const {'limit': 50},
      );
      return _readList(response).map(TravelRoute.fromJson).toList();
    } catch (error) {
      throw mapDioError(error);
    }
  }

  Future<List<TravelRoute>> fetchSavedRoutes() async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.routesSaved,
        queryParameters: const {'limit': 50},
      );
      return _readList(response).map(TravelRoute.fromJson).toList();
    } catch (error) {
      throw mapDioError(error);
    }
  }

  Future<TravelRoute> fetchByShareSlug(String slug) async {
    final response = await _dio.get<dynamic>(ApiEndpoints.routeShare(slug));
    return TravelRoute.fromJson(unwrapData(response) as Map<String, dynamic>);
  }

  Future<TravelRoute> createRoute({
    required String title,
    required List<int> destinationIds,
    String visibility = 'private',
  }) async {
    final response = await _dio.post<dynamic>(
      ApiEndpoints.routes,
      data: {
        'title': title,
        'visibility': visibility,
        'autoSort': true,
        'stops': [
          for (final entry in destinationIds.indexed)
            {
              'destinationId': entry.$2,
              'stopOrder': entry.$1 + 1,
              'estimatedVisitMinutes': 90,
            },
        ],
      },
    );
    return TravelRoute.fromJson(unwrapData(response) as Map<String, dynamic>);
  }

  Future<void> saveRoute(int id) async {
    await _dio.post<dynamic>(ApiEndpoints.routeSave(id));
  }

  Future<void> unsaveRoute(int id) async {
    await _dio.delete<dynamic>(ApiEndpoints.routeSave(id));
  }

  Future<SavedRouteProgress> fetchSavedRouteProgress(int routeId) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.routeSavedProgress(routeId),
      );
      return SavedRouteProgress.fromJson(
        unwrapData(response) as Map<String, dynamic>,
      );
    } catch (error) {
      throw mapDioError(error);
    }
  }

  Future<void> markStopVisited({
    required int routeId,
    required int routeStopId,
  }) async {
    await _dio.put<dynamic>(
      ApiEndpoints.routeSavedProgressStop(routeId, routeStopId),
      data: const {'status': 'visited'},
    );
  }

  Future<void> resetStopProgress({
    required int routeId,
    required int routeStopId,
  }) async {
    await _dio.delete<dynamic>(
      ApiEndpoints.routeSavedProgressStop(routeId, routeStopId),
    );
  }
}

List<Map<String, dynamic>> _readList(Response<dynamic> response) {
  final data = unwrapData(response);
  if (data is List) return data.whereType<Map<String, dynamic>>().toList();
  if (data is Map<String, dynamic> && data['data'] is List) {
    return (data['data'] as List).whereType<Map<String, dynamic>>().toList();
  }
  return [];
}
