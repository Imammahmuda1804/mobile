import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/api_endpoints.dart';
import '../../../core/constants/destination_categories.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/network/dio_client.dart';
import 'search_models.dart';

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepository(ref.read(dioProvider));
});

class SearchHistoryItem {
  const SearchHistoryItem({
    this.id,
    required this.keyword,
    this.createdAt,
  });

  final int? id;
  final String keyword;
  final String? createdAt;

  factory SearchHistoryItem.fromJson(Map<String, dynamic> json) {
    return SearchHistoryItem(
      id: json['id'] is int ? json['id'] as int : int.tryParse('${json['id']}'),
      keyword: (json['keyword'] ?? json['query'])?.toString() ?? '',
      createdAt: json['createdAt']?.toString(),
    );
  }
}

// Repository API untuk keyword search, semantic search, kota, history, dan rekomendasi.
class SearchRepository {
  const SearchRepository(this._dio);

  final Dio _dio;

  Future<List<DestinationSummary>> searchKeyword({
    String? query,
    String? city,
    String? category,
  }) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.destinations,
        queryParameters: {
          'limit': 20,
          if (query != null && query.isNotEmpty) 'search': query,
          if (city != null && city.isNotEmpty) 'city': city,
          if (category != null && category.isNotEmpty) 'category': category,
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
    String? city,
    String? category,
  }) async {
    try {
      final response = await _dio.post<dynamic>(
        ApiEndpoints.search,
        data: {
          'query': query,
          'sort': sort,
          if (city != null && city.isNotEmpty) 'city': city,
          if (category != null && category.isNotEmpty) 'category': category,
        },
      );
      return _readList(response).map(DestinationSummary.fromJson).toList();
    } catch (error) {
      throw mapDioError(error);
    }
  }

  Future<List<TopicFilter>> fetchTopics() async {
    final response = await _dio.get<dynamic>(
      ApiEndpoints.topics,
      queryParameters: const {'scope': 'search'},
    );
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

  Future<List<DestinationCategoryOption>> fetchCategories() async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.destinationCategories,
      );
      final data = unwrapData(response);
      final list = data is List
          ? data
          : data is Map<String, dynamic> && data['data'] is List
              ? data['data'] as List
              : const [];
      final categories = list
          .whereType<Map<String, dynamic>>()
          .map(
            (item) => DestinationCategoryOption(
              value: item['value']?.toString() ?? '',
              label: item['label']?.toString() ??
                  item['value']?.toString() ??
                  '',
            ),
          )
          .where((item) => item.value.isNotEmpty && item.label.isNotEmpty)
          .toList();

      return categories.isEmpty ? destinationCategories : categories;
    } catch (_) {
      return destinationCategories;
    }
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

  Future<List<SearchHistoryItem>> fetchHistory() async {
    try {
      final response = await _dio.get<dynamic>(ApiEndpoints.searchHistory);
      return _readList(response)
          .map(SearchHistoryItem.fromJson)
          .where((item) => item.keyword.isNotEmpty)
          .take(6)
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> deleteHistoryItem(int id) async {
    await _dio.delete<dynamic>(ApiEndpoints.searchHistoryItem(id));
  }

  Future<void> clearHistory() async {
    await _dio.delete<dynamic>(ApiEndpoints.searchHistory);
  }
}

// Membaca list dari response backend yang bisa terbungkus.
List<Map<String, dynamic>> _readList(Response<dynamic> response) {
  final data = unwrapData(response);
  if (data is List) return data.whereType<Map<String, dynamic>>().toList();
  if (data is Map<String, dynamic> && data['data'] is List) {
    return (data['data'] as List).whereType<Map<String, dynamic>>().toList();
  }
  return [];
}
