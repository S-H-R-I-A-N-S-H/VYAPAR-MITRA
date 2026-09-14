/// Data model representing a nearby competitor business discovered via Mappls.
class CompetitorPoi {
  final String id;
  final String name;
  final double distanceKm;
  final String category;
  final String address;
  final double latitude;
  final double longitude;
  final String estimatedCapacity;
  final String pricePoint;
  final String differentiationTip;
  final bool isDirectCompetitor;

  const CompetitorPoi({
    required this.id,
    required this.name,
    required this.distanceKm,
    required this.category,
    required this.address,
    required this.latitude,
    required this.longitude,
    this.estimatedCapacity = 'Medium',
    this.pricePoint = 'Market Standard',
    this.differentiationTip = 'Compete on freshness, purity, and localized customer service.',
    this.isDirectCompetitor = true,
  });

  factory CompetitorPoi.fromJson(Map<String, dynamic> json, {double? fallbackLat, double? fallbackLon, int index = 0}) {
    // Generate realistic geographic offsets around center if exact lat/lon are not returned
    final dist = (json['distance_km'] as num?)?.toDouble() ?? 1.5;
    // Radial dispersion for visual map placement
    final angle = (index * 72) * (3.1415926535 / 180.0);
    final offsetLat = (dist / 111.0) * 0.7 * (index % 2 == 0 ? 1 : -1);
    final offsetLon = (dist / 111.0) * 0.7 * (index % 3 == 0 ? 1 : -1) + (angle * 0.0001);

    final lat = (json['latitude'] as num?)?.toDouble() ??
        ((fallbackLat ?? 22.9772) + offsetLat);
    final lon = (json['longitude'] as num?)?.toDouble() ??
        ((fallbackLon ?? 75.8078) + offsetLon);

    final name = json['name'] as String? ?? 'Local Competitor';
    final category = json['category'] as String? ?? 'Agri-Business';
    final address = json['address'] as String? ?? 'Nearby Market Yard';

    String capacity = '100-200 kg/day';
    String pricePoint = '₹180/L';
    String differentiation = 'Focus on cold-pressed unrefined purity; competitor only offers standard expeller.';

    if (category.toLowerCase().contains('dairy') || name.toLowerCase().contains('dairy')) {
      capacity = '300 L/day collection';
      pricePoint = '₹52/L buying';
      differentiation = 'Offer higher fat-testing transparency and instant UPI spot settlement.';
    } else if (category.toLowerCase().contains('flour') || category.toLowerCase().contains('chakki')) {
      capacity = '50 kg/hour milling';
      pricePoint = '₹6/kg grinding charge';
      differentiation = 'Provide multi-grain custom blending and doorstep pickup/delivery.';
    }

    return CompetitorPoi(
      id: json['id']?.toString() ?? 'comp_$index',
      name: name,
      distanceKm: dist,
      category: category,
      address: address,
      latitude: lat,
      longitude: lon,
      estimatedCapacity: json['estimated_capacity'] ?? capacity,
      pricePoint: json['price_point'] ?? pricePoint,
      differentiationTip: json['differentiation_tip'] ?? differentiation,
      isDirectCompetitor: json['is_direct_competitor'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'distance_km': distanceKm,
      'category': category,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'estimated_capacity': estimatedCapacity,
      'price_point': pricePoint,
      'differentiation_tip': differentiationTip,
      'is_direct_competitor': isDirectCompetitor,
    };
  }
}
