import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/api_endpoints.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/network/dio_client.dart';
import 'search_models.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepository(ref.read(dioProvider));
});

class SearchRepository {
  const SearchRepository(this._dio);

  final Dio _dio;

  Future<List<DestinationSummary>> searchKeyword({
    String? query,
    List<int> topicIds = const [],
    String? city,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.destinations,
        queryParameters: {
          'limit': 20,
          if (query != null && query.isNotEmpty) 'search': query,
          if (topicIds.isNotEmpty) 'topic_ids': topicIds.join(','),
          if (city != null && city.isNotEmpty) 'city': city,
        },
      );
      return _readList(response).map(DestinationSummary.fromJson).toList();
    } catch (error) {
      throw mapDioError(error);
    }
  }

  Future<List<DestinationSummary>> searchSemantic({
    required String query,
    String sort = 'hybrid',
    List<int> topicIds = const [],
    String? city,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.search,
        data: {
          'query': query,
          'sort': sort,
          if (topicIds.isNotEmpty) 'topic_ids': topicIds,
          if (city != null && city.isNotEmpty) 'city': city,
        },
      );
      return _readList(response).map(DestinationSummary.fromJson).toList();
    } catch (error) {
      throw mapDioError(error);
    }
  }

  Future<List<TopicFilter>> fetchTopics() async {
    final response = await _dio.get<dynamic>(ApiEndpoints.topics);
    return _readList(response).map(TopicFilter.fromJson).toList();
  }

  Future<List<String>> fetchCities() async {
    final response = await _dio.get<dynamic>(ApiEndpoints.destinationCities);
    final data = unwrapData(response);
    if (data is List) return data.map((item) => item.toString()).toList();
    if (data is Map<String, dynamic> && data['data'] is List) {
      return (data['data'] as List).map((item) => item.toString()).toList();
    }
    return [];
  }

  Future<List<DestinationSummary>> fetchRecommendations() async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.destinationRecommendations,
      );
      return _readList(response).map(DestinationSummary.fromJson).toList();
    } catch (_) {
      final response = await _dio.get<dynamic>(ApiEndpoints.destinationRanking);
      return _readList(response).map(DestinationSummary.fromJson).toList();
    }
  }

  Future<List<String>> fetchHistory() async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.searchHistory);
      return _readList(response)
          .map((item) => (item['keyword'] ?? item['query'])?.toString() ?? '')
          .where((item) => item.isNotEmpty)
          .take(6)
          .toList();
    } catch (_) {
      return const [];
    }
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
