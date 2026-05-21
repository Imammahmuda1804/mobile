import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../search/data/search_models.dart';
import '../../search/data/search_repository.dart';

final homeRepositoryProvider = Provider<HomeRepository>((ref) {
  return HomeRepository(ref.read(searchRepositoryProvider));
});

// Repository API untuk rekomendasi dan trending di home.
class HomeRepository {
  const HomeRepository(this._searchRepository);

  final SearchRepository _searchRepository;

  Future<List<DestinationSummary>> fetchTrending() {
    return _searchRepository.fetchRecommendations();
  }
}
