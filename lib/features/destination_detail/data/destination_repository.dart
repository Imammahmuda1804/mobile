import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/api_endpoints.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/network/dio_client.dart';
import 'destination_models.dart';

final destinationRepositoryProvider = Provider<DestinationRepository>((ref) {
  return DestinationRepository(ref.read(dioProvider));
});

// Repository API untuk detail destinasi, favorit, topik review, dan submit review.
class DestinationRepository {
  const DestinationRepository(this._dio);

  final Dio _dio;

  Future<DestinationDetail> fetchBySlug(String slug) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.destinationBySlug(slug),
      );
      return DestinationDetail.fromJson(
        unwrapData(response) as Map<String, dynamic>,
      );
    } catch (error) {
      throw mapDioError(error);
    }
  }

  Future<bool> checkFavorite(int destinationId) async {
    final response = await _dio.get<dynamic>(
      ApiEndpoints.favoriteCheck(destinationId),
    );
    final data = unwrapData(response);
    if (data is Map<String, dynamic>) {
      return data['isFavorite'] == true;
    }
    return false;
  }

  Future<void> addFavorite(int destinationId) {
    return _dio.post<dynamic>(
      ApiEndpoints.favoriteByDestination(destinationId),
    );
  }

  Future<void> removeFavorite(int destinationId) {
    return _dio.delete<dynamic>(
      ApiEndpoints.favoriteByDestination(destinationId),
    );
  }

  Future<List<ScrapedTopicReview>> fetchReviewsByTopic({
    required int destinationId,
    required int topicId,
    int limit = 10,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.destinationReviewsByTopic(destinationId),
        queryParameters: {
          'topicId': topicId,
          'page': 1,
          'limit': limit,
        },
      );
      final data = unwrapData(response);
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(ScrapedTopicReview.fromJson)
            .toList();
      }
      return const [];
    } catch (error) {
      throw mapDioError(error);
    }
  }

  Future<List<ScrapedTopicReview>> fetchReviewsByTopicGroup({
    required int destinationId,
    required int groupId,
    int limit = 10,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.destinationReviewsByTopicGroup(destinationId),
        queryParameters: {
          'groupId': groupId,
          'page': 1,
          'limit': limit,
        },
      );
      final data = unwrapData(response);
      if (data is List) {
        return data
            .whereType<Map<String, dynamic>>()
            .map(ScrapedTopicReview.fromJson)
            .toList();
      }
      return const [];
    } catch (error) {
      throw mapDioError(error);
    }
  }

  Future<void> submitReview({
    required int destinationId,
    required int rating,
    required String reviewText,
  }) {
    return _dio.post<dynamic>(
      ApiEndpoints.userReviews,
      data: {
        'destination_id': destinationId,
        'rating': rating,
        if (reviewText.isNotEmpty) 'review_text': reviewText,
      },
    );
  }
}
