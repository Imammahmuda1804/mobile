// Model destinasi dalam hasil compare.
class ComparedDestination {
  const ComparedDestination({
    required this.id,
    required this.name,
    required this.city,
    this.slug,
    this.province,
    this.category,
    this.thumbnailUrl,
    this.latitude,
    this.longitude,
    this.googleMapsUrl,
    this.reviewCount = 0,
    this.recommendationScore,
    this.positiveRatio,
    this.userRating,
    this.googleRating,
    this.positive = 0,
    this.neutral = 0,
    this.negative = 0,
    this.topics = const [],
    this.highlights = const [],
    this.risks = const [],
    this.travelTraits = const {},
    this.decisionFactors = const {},
  });

  factory ComparedDestination.fromJson(Map<String, dynamic> json) {
    final rating = json['rating'];
    final sentiment = json['sentiment'];
    final rawTopics = json['topics'];
    return ComparedDestination(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      slug: json['slug']?.toString(),
      province: json['province']?.toString(),
      category: json['category']?.toString(),
      thumbnailUrl: json['thumbnailUrl']?.toString(),
      latitude: _num(json['latitude']),
      longitude: _num(json['longitude']),
      googleMapsUrl: json['googleMapsUrl']?.toString(),
      reviewCount: int.tryParse('${json['review_count'] ?? ''}') ?? 0,
      recommendationScore: _num(json['recommendation_score']),
      positiveRatio: _num(json['positive_ratio']),
      userRating: rating is Map<String, dynamic> ? _num(rating['user']) : null,
      googleRating:
          rating is Map<String, dynamic> ? _num(rating['google']) : null,
      positive: sentiment is Map<String, dynamic>
          ? int.tryParse(sentiment['positive'].toString()) ?? 0
          : 0,
      neutral: sentiment is Map<String, dynamic>
          ? int.tryParse(sentiment['neutral'].toString()) ?? 0
          : 0,
      negative: sentiment is Map<String, dynamic>
          ? int.tryParse(sentiment['negative'].toString()) ?? 0
          : 0,
      topics: rawTopics is List
          ? rawTopics
              .whereType<Map<String, dynamic>>()
              .map((item) => CompareTopic.fromJson(item))
              .toList()
          : const [],
      highlights: _readStringList(json['highlights']),
      risks: _readStringList(json['risks']),
      travelTraits: _readScoreMap(json['travel_traits']),
      decisionFactors: _readScoreMap(json['decision_factors']),
    );
  }

  final int id;
  final String name;
  final String city;
  final String? slug;
  final String? province;
  final String? category;
  final String? thumbnailUrl;
  final num? latitude;
  final num? longitude;
  final String? googleMapsUrl;
  final int reviewCount;
  final num? recommendationScore;
  final num? positiveRatio;
  final num? userRating;
  final num? googleRating;
  final int positive;
  final int neutral;
  final int negative;
  final List<CompareTopic> topics;
  final List<String> highlights;
  final List<String> risks;
  final Map<String, num> travelTraits;
  final Map<String, num> decisionFactors;
}

class CompareTopic {
  const CompareTopic({required this.name, required this.totalReviews});

  factory CompareTopic.fromJson(Map<String, dynamic> json) {
    return CompareTopic(
      name: json['topic_name']?.toString().replaceFirst(
                RegExp(r'^Topic \d+:\s*'),
                '',
              ) ??
          'Topik',
      totalReviews: int.tryParse(json['total_reviews'].toString()) ?? 0,
    );
  }

  final String name;
  final int totalReviews;
}

// Model hasil perbandingan dua destinasi.
class CompareResult {
  const CompareResult({
    required this.destination1,
    required this.destination2,
    this.winnerId,
    this.scoreDifference = 0,
    this.summary,
    this.bestFor = const [],
    this.tradeoffs = const [],
  });

  factory CompareResult.fromJson(Map<String, dynamic> json) {
    final comparison = _readMap(json['comparison']);
    final insights = _readMap(comparison?['insights']);
    return CompareResult(
      destination1: ComparedDestination.fromJson(
        json['destination1'] as Map<String, dynamic>,
      ),
      destination2: ComparedDestination.fromJson(
        json['destination2'] as Map<String, dynamic>,
      ),
      winnerId: int.tryParse(
        comparison?['recommendation_winner'].toString() ?? '',
      ),
      scoreDifference: _num(comparison?['score_difference']) ?? 0,
      summary: insights?['summary']?.toString(),
      bestFor: _readStringList(insights?['best_for']),
      tradeoffs: _readStringList(insights?['tradeoffs']),
    );
  }

  final ComparedDestination destination1;
  final ComparedDestination destination2;
  final int? winnerId;
  final num scoreDifference;
  final String? summary;
  final List<String> bestFor;
  final List<String> tradeoffs;
}

num? _num(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  return num.tryParse(value.toString());
}

List<String> _readStringList(dynamic value) {
  if (value is! List) return const [];
  return value
      .map((item) => item.toString())
      .where((item) => item.isNotEmpty)
      .toList();
}

Map<String, num> _readScoreMap(dynamic value) {
  if (value is! Map) return const {};
  final result = <String, num>{};
  for (final entry in value.entries) {
    result[entry.key.toString()] = _num(entry.value) ?? 0;
  }
  return result;
}

Map<String, dynamic>? _readMap(dynamic value) {
  if (value is! Map) return null;
  final result = <String, dynamic>{};
  for (final entry in value.entries) {
    result[entry.key.toString()] = entry.value;
  }
  return result;
}
