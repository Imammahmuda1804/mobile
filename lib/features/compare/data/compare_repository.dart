import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/config/api_endpoints.dart';
import '../../../core/errors/error_mapper.dart';
import '../../../core/network/dio_client.dart';
import '../../search/data/search_models.dart';
import '../../search/data/search_repository.dart';
import 'compare_models.dart';

final compareRepositoryProvider = Provider<CompareRepository>((ref) {
  return CompareRepository(
    ref.read(dioProvider),
    ref.read(searchRepositoryProvider),
  );
});

// Repository API untuk daftar destinasi dan hasil perbandingan.
class CompareRepository {
  const CompareRepository(this._dio, this._searchRepository);

  final Dio _dio;
  final SearchRepository _searchRepository;

  Future<List<DestinationSummary>> fetchDestinations() {
    return _searchRepository.searchKeyword();
  }

  Future<CompareResult> compare(int firstId, int secondId) async {
    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.compare,
        queryParameters: {'destination1': firstId, 'destination2': secondId},
      );
      return CompareResult.fromJson(
        unwrapData(response) as Map<String, dynamic>,
      );
    } catch (error) {
      throw mapDioError(error);
    }
  }
}
