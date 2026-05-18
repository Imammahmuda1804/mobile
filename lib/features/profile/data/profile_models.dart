import '../../search/data/search_models.dart';

class FavoriteDestination {
  const FavoriteDestination({
    required this.id,
    required this.createdAt,
    required this.destination,
  });

  factory FavoriteDestination.fromJson(Map<String, dynamic> json) {
    final destination = json['destination'];
    if (destination is! Map<String, dynamic>) {
      throw const FormatException('Data destinasi favorit tidak valid.');
    }

    return FavoriteDestination(
      id: int.tryParse(json['id'].toString()) ?? 0,
      createdAt: json['createdAt']?.toString() ?? '',
      destination: DestinationSummary.fromJson(destination),
    );
  }

  final int id;
  final String createdAt;
  final DestinationSummary destination;
}
