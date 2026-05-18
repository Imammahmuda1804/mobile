class ComparedDestination {
  const ComparedDestination({
    required this.id,
    required this.name,
    required this.city,
    this.slug,
    this.recommendationScore,
    this.positiveRatio,
    this.userRating,
    this.googleRating,
    this.positive = 0,
    this.neutral = 0,
    this.negative = 0,
    this.topics = const [],
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
    );
  }

  final int id;
  final String name;
  final String city;
  final String? slug;
  final num? recommendationScore;
  final num? positiveRatio;
  final num? userRating;
  final num? googleRating;
  final int positive;
  final int neutral;
  final int negative;
  final List<CompareTopic> topics;
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

class CompareResult {
  const CompareResult({
    required this.destination1,
    required this.destination2,
    this.winnerId,
    this.scoreDifference = 0,
  });

  factory CompareResult.fromJson(Map<String, dynamic> json) {
    final comparison = json['comparison'];
    return CompareResult(
      destination1: ComparedDestination.fromJson(
        json['destination1'] as Map<String, dynamic>,
      ),
      destination2: ComparedDestination.fromJson(
        json['destination2'] as Map<String, dynamic>,
      ),
      winnerId: comparison is Map<String, dynamic>
          ? int.tryParse(comparison['recommendation_winner'].toString())
          : null,
      scoreDifference: comparison is Map<String, dynamic>
          ? _num(comparison['score_difference']) ?? 0
          : 0,
    );
  }

  final ComparedDestination destination1;
  final ComparedDestination destination2;
  final int? winnerId;
  final num scoreDifference;
}

num? _num(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  return num.tryParse(value.toString());
}
