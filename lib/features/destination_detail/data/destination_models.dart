import '../../../core/utils/image_url.dart';
import '../../search/data/search_models.dart';

class DestinationDetail {
  const DestinationDetail({
    required this.id,
    required this.name,
    required this.slug,
    required this.city,
    required this.province,
    required this.description,
    required this.imageUrl,
    required this.googleMapsUrl,
    this.youtubeUrl,
    this.googleRating,
    this.googleReviewCount,
    this.scrapedAverageRating,
    this.scrapedReviewCount,
    this.averageUserRating,
    this.totalUserReviews = 0,
    this.positiveRatio,
    this.recommendationScore,
    this.userRating,
    this.images = const [],
    this.topics = const [],
    this.topicSentiments = const {},
    this.userReviews = const [],
  });

  factory DestinationDetail.fromJson(Map<String, dynamic> json) {
    final rawImages = json['images'];
    final rawTopics = json['destinationTopics'];
    final rawReviews = json['userReviews'];

    return DestinationDetail(
      id: int.tryParse(json['id'].toString()) ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      province: json['province']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      imageUrl: resolveImageUrl(
        (json['thumbnailUrl'] ?? json['thumbnail_url'])?.toString(),
      ),
      googleMapsUrl: json['googleMapsUrl']?.toString() ?? '',
      youtubeUrl: json['youtubeUrl']?.toString(),
      googleRating: _num(json['googleRating']),
      googleReviewCount: _num(json['googleReviewCount']),
      scrapedAverageRating: _num(json['scrapedAverageRating']),
      scrapedReviewCount: _int(json['scrapedReviewCount']),
      averageUserRating: _num(json['averageUserRating']),
      totalUserReviews:
          _int(json['totalUserReviews'] ?? json['userReviewsCount']) ?? 0,
      positiveRatio: _num(json['positiveRatio']),
      recommendationScore: _num(json['recommendationScore']),
      userRating: _num(json['userRating']),
      images: rawImages is List
          ? rawImages
              .whereType<Map<String, dynamic>>()
              .map((item) => resolveImageUrl(item['imageUrl']?.toString()))
              .where((url) => url.isNotEmpty)
              .toList()
          : const [],
      topics: rawTopics is List
          ? rawTopics
              .whereType<Map<String, dynamic>>()
              .map((item) {
                final topic = item['topic'];
                return topic is Map<String, dynamic>
                    ? DestinationTopic.fromJson({
                        'id': topic['id'],
                        'topicName': topic['topicName'],
                      })
                    : null;
              })
              .whereType<DestinationTopic>()
              .toList()
          : const [],
      topicSentiments: _parseTopicSentiments(json['topicSentimentBreakdown']),
      userReviews: rawReviews is List
          ? rawReviews
              .whereType<Map<String, dynamic>>()
              .map(UserReview.fromJson)
              .toList()
          : const [],
    );
  }

  final int id;
  final String name;
  final String slug;
  final String city;
  final String province;
  final String description;
  final String imageUrl;
  final String googleMapsUrl;
  final String? youtubeUrl;
  final num? googleRating;
  final num? googleReviewCount;
  final num? scrapedAverageRating;
  final int? scrapedReviewCount;
  final num? averageUserRating;
  final int totalUserReviews;
  final num? positiveRatio;
  final num? recommendationScore;
  final num? userRating;
  final List<String> images;
  final List<DestinationTopic> topics;
  final Map<int, TopicSentimentBreakdown> topicSentiments;
  final List<UserReview> userReviews;
}

class TopicSentimentBreakdown {
  const TopicSentimentBreakdown({
    this.positive = 0,
    this.negative = 0,
    this.neutral = 0,
  });

  factory TopicSentimentBreakdown.fromJson(Map<String, dynamic> json) {
    return TopicSentimentBreakdown(
      positive: _int(json['positive']) ?? 0,
      negative: _int(json['negative']) ?? 0,
      neutral: _int(json['neutral']) ?? 0,
    );
  }

  final int positive;
  final int negative;
  final int neutral;

  int get total => positive + negative + neutral;
}

class ScrapedTopicReview {
  const ScrapedTopicReview({
    required this.id,
    required this.reviewerName,
    required this.reviewText,
    required this.rating,
    required this.reviewDate,
    this.sentiment,
    this.likesCount = 0,
  });

  factory ScrapedTopicReview.fromJson(Map<String, dynamic> json) {
    return ScrapedTopicReview(
      id: _int(json['id']) ?? 0,
      reviewerName: json['reviewerName']?.toString() ?? 'Wisatawan',
      reviewText: json['reviewText']?.toString() ?? '',
      rating: _num(json['rating']),
      reviewDate: json['reviewDate']?.toString() ?? '',
      sentiment: json['sentiment']?.toString(),
      likesCount: _int(json['likesCount']) ?? 0,
    );
  }

  final int id;
  final String reviewerName;
  final String reviewText;
  final num? rating;
  final String reviewDate;
  final String? sentiment;
  final int likesCount;
}

class UserReview {
  const UserReview({
    required this.id,
    required this.rating,
    required this.userName,
    required this.createdAt,
    this.userAvatar,
    this.reviewText,
  });

  factory UserReview.fromJson(Map<String, dynamic> json) {
    final user = json['user'];
    return UserReview(
      id: int.tryParse(json['id'].toString()) ?? 0,
      rating: int.tryParse(json['rating'].toString()) ?? 0,
      userName: user is Map<String, dynamic>
          ? user['name']?.toString() ?? 'Pengguna'
          : 'Pengguna',
      userAvatar: user is Map<String, dynamic>
          ? user['profilePicture']?.toString()
          : null,
      createdAt: json['createdAt']?.toString() ?? '',
      reviewText: json['reviewText']?.toString(),
    );
  }

  final int id;
  final int rating;
  final String userName;
  final String createdAt;
  final String? userAvatar;
  final String? reviewText;
}

num? _num(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  return num.tryParse(value.toString());
}

int? _int(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.round();
  return int.tryParse(value.toString());
}

Map<int, TopicSentimentBreakdown> _parseTopicSentiments(dynamic value) {
  if (value is! Map) return const {};

  final result = <int, TopicSentimentBreakdown>{};
  for (final entry in value.entries) {
    final topicId = int.tryParse(entry.key.toString());
    final raw = entry.value;
    if (topicId == null || raw is! Map<String, dynamic>) continue;
    result[topicId] = TopicSentimentBreakdown.fromJson(raw);
  }
  return result;
}
