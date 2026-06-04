import '../../../core/utils/image_url.dart';

class TravelRoute {
  const TravelRoute({
    required this.id,
    required this.title,
    required this.shareSlug,
    required this.visibility,
    required this.stops,
    this.description,
    this.city,
    this.isAdminCurated = false,
    this.totalDistanceKm,
    this.estimatedDurationMinutes,
  });

  factory TravelRoute.fromJson(Map<String, dynamic> json) {
    final rawStops = json['stops'];
    return TravelRoute(
      id: int.tryParse('${json['id']}') ?? 0,
      title: json['title']?.toString() ?? '',
      shareSlug: json['shareSlug']?.toString() ?? '',
      visibility: json['visibility']?.toString() ?? 'private',
      description: json['description']?.toString(),
      city: json['city']?.toString(),
      isAdminCurated: json['isAdminCurated'] == true,
      totalDistanceKm: _num(json['totalDistanceKm']),
      estimatedDurationMinutes: int.tryParse(
        '${json['estimatedDurationMinutes'] ?? ''}',
      ),
      stops: rawStops is List
          ? rawStops
              .whereType<Map<String, dynamic>>()
              .map(RouteStop.fromJson)
              .toList()
          : const [],
    );
  }

  final int id;
  final String title;
  final String shareSlug;
  final String visibility;
  final String? description;
  final String? city;
  final bool isAdminCurated;
  final num? totalDistanceKm;
  final int? estimatedDurationMinutes;
  final List<RouteStop> stops;
}

class RouteStop {
  const RouteStop({
    required this.id,
    required this.destinationId,
    required this.stopOrder,
    this.distanceToNextKm,
    this.estimatedVisitMinutes,
    this.note,
    this.destination,
  });

  factory RouteStop.fromJson(Map<String, dynamic> json) {
    final destination = json['destination'];
    return RouteStop(
      id: int.tryParse('${json['id']}') ?? 0,
      destinationId: int.tryParse('${json['destinationId']}') ?? 0,
      stopOrder: int.tryParse('${json['stopOrder']}') ?? 0,
      distanceToNextKm: _num(json['distanceToNextKm']),
      estimatedVisitMinutes: int.tryParse(
        '${json['estimatedVisitMinutes'] ?? ''}',
      ),
      note: json['note']?.toString(),
      destination: destination is Map<String, dynamic>
          ? RouteDestination.fromJson(destination)
          : null,
    );
  }

  final int id;
  final int destinationId;
  final int stopOrder;
  final num? distanceToNextKm;
  final int? estimatedVisitMinutes;
  final String? note;
  final RouteDestination? destination;
}

class SavedRouteProgress {
  const SavedRouteProgress({
    required this.savedRouteId,
    required this.routeId,
    required this.items,
  });

  factory SavedRouteProgress.fromJson(Map<String, dynamic> json) {
    final rawItems = json['progress'];
    return SavedRouteProgress(
      savedRouteId: int.tryParse('${json['savedRouteId']}') ?? 0,
      routeId: int.tryParse('${json['routeId']}') ?? 0,
      items: rawItems is List
          ? rawItems
              .whereType<Map<String, dynamic>>()
              .map(SavedRouteProgressItem.fromJson)
              .toList()
          : const [],
    );
  }

  final int savedRouteId;
  final int routeId;
  final List<SavedRouteProgressItem> items;

  Set<int> get visitedStopIds => items
      .where((item) => item.status == 'visited')
      .map((item) => item.routeStopId)
      .toSet();
}

class SavedRouteProgressItem {
  const SavedRouteProgressItem({
    required this.routeStopId,
    required this.status,
    this.note,
    this.visitedAt,
    this.updatedAt,
  });

  factory SavedRouteProgressItem.fromJson(Map<String, dynamic> json) {
    return SavedRouteProgressItem(
      routeStopId: int.tryParse('${json['routeStopId']}') ?? 0,
      status: json['status']?.toString() ?? 'pending',
      note: json['note']?.toString(),
      visitedAt: json['visitedAt']?.toString(),
      updatedAt: json['updatedAt']?.toString(),
    );
  }

  final int routeStopId;
  final String status;
  final String? note;
  final String? visitedAt;
  final String? updatedAt;
}

class RouteDestination {
  const RouteDestination({
    required this.id,
    required this.name,
    required this.slug,
    required this.city,
    required this.province,
    required this.imageUrl,
    this.latitude,
    this.longitude,
    this.googleMapsUrl,
  });

  factory RouteDestination.fromJson(Map<String, dynamic> json) {
    return RouteDestination(
      id: int.tryParse('${json['id']}') ?? 0,
      name: json['name']?.toString() ?? '',
      slug: json['slug']?.toString() ?? '',
      city: json['city']?.toString() ?? '',
      province: json['province']?.toString() ?? '',
      imageUrl: resolveImageUrl(
        (json['thumbnailUrl'] ?? json['thumbnail_url'])?.toString(),
      ),
      latitude: _num(json['latitude']),
      longitude: _num(json['longitude']),
      googleMapsUrl: json['googleMapsUrl']?.toString(),
    );
  }

  final int id;
  final String name;
  final String slug;
  final String city;
  final String province;
  final String imageUrl;
  final num? latitude;
  final num? longitude;
  final String? googleMapsUrl;
}

num? _num(dynamic value) {
  if (value == null) return null;
  if (value is num) return value;
  return num.tryParse(value.toString());
}
