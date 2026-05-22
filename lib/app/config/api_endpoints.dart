class ApiEndpoints {
  const ApiEndpoints._();

  static const login = '/api/auth/login';
  static const register = '/api/auth/register';
  static const refresh = '/api/auth/refresh';
  static const destinations = '/api/destinations';
  static const destinationRecommendations = '/api/destinations/recommendations';
  static const destinationRanking = '/api/destinations/ranking';
  static const destinationCities = '/api/destinations/cities';
  static const destinationCategories = '/api/destinations/categories';
  static const search = '/api/search';
  static const searchHistory = '/api/search/history';
  static const topics = '/api/topics';
  static const compare = '/api/analytics/compare';
  static const favorites = '/api/favorites';
  static const usersMe = '/api/users/me';
  static const usersMeAvatar = '/api/users/me/avatar';
  static const userReviews = '/api/user-reviews';

  static String destinationBySlug(String slug) =>
      '/api/destinations/slug/$slug';
  static String destinationReviewsByTopic(int id) =>
      '/api/destinations/$id/reviews-by-topic';
  static String destinationReviewsByTopicGroup(int id) =>
      '/api/destinations/$id/reviews-by-topic-group';
  static String favoriteCheck(int id) => '/api/favorites/check/$id';
  static String favoriteByDestination(int id) => '/api/favorites/$id';
  static String searchHistoryItem(int id) => '/api/search/history/$id';
}
