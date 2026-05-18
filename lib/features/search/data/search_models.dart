import '../../../core/utils/image_url.dart';

class DestinationTopic {
  const DestinationTopic({required this.id, required this.name});

  factory DestinationTopic.fromJson(Map<String, dynamic> json) {
    return DestinationTopic(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: (json['topic_name'] ?? json['topicName'] ?? json['name'] ?? 'Vibe')
          .toString()
          .replaceFirst(RegExp(r'^Topic \d+:\s*'), ''),
    );
  }

  final int id;
  final String name;
}

class DestinationSummary {
  const DestinationSummary({
    required this.id,
    required this.name,
    required this.slug,
    required this.city,
    required this.imageUrl,
    this.province,
    this.description,
    this.positiveRatio,
    this.recommendationScore,
    this.matchScore,
    this.googleRating,
    this.topics = const [],
  });

  factory DestinationSummary.fromJson(Map<String, dynamic> json) {
    final rawTopics = json['topics'];
    return DestinationSummary(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      province: json['province']?.toString(),
      imageUrl: resolveImageUrl(
        (json['thumbnailUrl'] ?? json['thumbnail_url'] ?? json['imageUrl'])
            ?.toString(),
      ),
      description: (json['shortDescription'] ??
              json['short_description'] ??
              json['description'])
          ?.toString(),
      positiveRatio: _num(json['positiveRatio'] ?? json['positive_ratio']),
      recommendationScore: _num(
        json['recommendationScore'] ?? json['recommendation_score'],
      ),
      matchScore: _num(json['hybrid_score'] ?? json['similarity']),
      googleRating: _num(json['googleRating'] ?? json['google_rating']),
      topics: rawTopics is List
          ? rawTopics
              .whereType<Map<String, dynamic>>()
              .map(DestinationTopic.fromJson)
              .toList()
          : const [],
    );
  }

  final int id;
  final String name;
  final String slug;
  final String city;
  final String? province;
  final String imageUrl;
  final String? description;
  final num? positiveRatio;
  final num? recommendationScore;
  final num? matchScore;
  final num? googleRating;
  final List<DestinationTopic> topics;
}

class TopicFilter {
  const TopicFilter({required this.id, required this.name});

  factory TopicFilter.fromJson(Map<String, dynamic> json) {
    return TopicFilter(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: (json['topic_name'] ?? json['topicName'] ?? 'Topik')
          .toString()
          .replaceFirst(RegExp(r'^Topic \d+:\s*'), ''),
    );
  }

  final int id;
  final String name;
}

num? _num(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  return num.tryParse(value.toString());
}
