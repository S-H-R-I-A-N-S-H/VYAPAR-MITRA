/// Data models for supplier freight economics and landed cost evaluation.
enum FreightVehicleMode {
  twoWheeler('two_wheeler', 'Two-Wheeler / बाइक', 6.0),
  autoRickshaw('auto_rickshaw', 'Auto-Rickshaw / ऑटो', 12.0),
  pickupTempo('pickup_tempo', 'Pickup Tempo / छोटा हाथी', 18.0),
  tractorTrolley('tractor_trolley', 'Tractor Trolley / ट्रैक्टर', 25.0);

  final String apiValue;
  final String label;
  final double defaultRatePerKm;

  const FreightVehicleMode(this.apiValue, this.label, this.defaultRatePerKm);

  static FreightVehicleMode fromApiValue(String val) {
    return FreightVehicleMode.values.firstWhere(
      (m) => m.apiValue == val,
      orElse: () => FreightVehicleMode.pickupTempo,
    );
  }
}

class SupplierCandidate {
  final String id;
  final String name;
  final double latitude;
  final double longitude;
  final double quotedPricePerUnit;
  final String unitName;
  final double minOrderQuantity;

  const SupplierCandidate({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.quotedPricePerUnit,
    this.unitName = 'kg',
    this.minOrderQuantity = 100.0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'quoted_price_per_unit': quotedPricePerUnit,
      'unit_name': unitName,
      'min_order_quantity': minOrderQuantity,
    };
  }
}

class SupplierLandedCostItem {
  final String supplierId;
  final String supplierName;
  final double distanceKm;
  final int durationMinutes;
  final double quotedPricePerUnit;
  final String unitName;
  final double minOrderQuantity;
  final double tripDistanceBilledKm;
  final double tripFreightCost;
  final double freightCostPerUnit;
  final double effectiveLandedCost;
  final double monthlyFreightTotal;
  final bool isRecommended;
  final bool isRealMappls;

  const SupplierLandedCostItem({
    required this.supplierId,
    required this.supplierName,
    required this.distanceKm,
    required this.durationMinutes,
    required this.quotedPricePerUnit,
    required this.unitName,
    required this.minOrderQuantity,
    required this.tripDistanceBilledKm,
    required this.tripFreightCost,
    required this.freightCostPerUnit,
    required this.effectiveLandedCost,
    required this.monthlyFreightTotal,
    required this.isRecommended,
    required this.isRealMappls,
  });

  factory SupplierLandedCostItem.fromJson(Map<String, dynamic> json) {
    return SupplierLandedCostItem(
      supplierId: json['supplier_id']?.toString() ?? '',
      supplierName: json['supplier_name']?.toString() ?? 'Supplier',
      distanceKm: (json['distance_km'] as num?)?.toDouble() ?? 0.0,
      durationMinutes: (json['duration_minutes'] as num?)?.toInt() ?? 0,
      quotedPricePerUnit: (json['quoted_price_per_unit'] as num?)?.toDouble() ?? 0.0,
      unitName: json['unit_name']?.toString() ?? 'unit',
      minOrderQuantity: (json['min_order_quantity'] as num?)?.toDouble() ?? 100.0,
      tripDistanceBilledKm: (json['trip_distance_billed_km'] as num?)?.toDouble() ?? 0.0,
      tripFreightCost: (json['trip_freight_cost'] as num?)?.toDouble() ?? 0.0,
      freightCostPerUnit: (json['freight_cost_per_unit'] as num?)?.toDouble() ?? 0.0,
      effectiveLandedCost: (json['effective_landed_cost'] as num?)?.toDouble() ?? 0.0,
      monthlyFreightTotal: (json['monthly_freight_total'] as num?)?.toDouble() ?? 0.0,
      isRecommended: json['is_recommended'] == true,
      isRealMappls: json['is_real_mappls'] == true,
    );
  }
}

class SupplierFreightEvaluationResult {
  final FreightVehicleMode vehicleMode;
  final double freightRatePerKm;
  final bool isRoundTrip;
  final int tripsPerMonth;
  final List<SupplierLandedCostItem> results;
  final String recommendedSupplierId;
  final double monthlySavingsVsWorst;
  final String insightSummaryEn;
  final String insightSummaryHi;
  final double monthlyOperatingCostDelta;

  const SupplierFreightEvaluationResult({
    required this.vehicleMode,
    required this.freightRatePerKm,
    required this.isRoundTrip,
    required this.tripsPerMonth,
    required this.results,
    required this.recommendedSupplierId,
    required this.monthlySavingsVsWorst,
    required this.insightSummaryEn,
    required this.insightSummaryHi,
    required this.monthlyOperatingCostDelta,
  });

  factory SupplierFreightEvaluationResult.fromJson(Map<String, dynamic> json) {
    final rawResults = json['results'] as List<dynamic>? ?? [];
    return SupplierFreightEvaluationResult(
      vehicleMode: FreightVehicleMode.fromApiValue(json['vehicle_mode']?.toString() ?? ''),
      freightRatePerKm: (json['freight_rate_per_km'] as num?)?.toDouble() ?? 18.0,
      isRoundTrip: json['is_round_trip'] != false,
      tripsPerMonth: (json['trips_per_month'] as num?)?.toInt() ?? 4,
      results: rawResults
          .map((e) => SupplierLandedCostItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      recommendedSupplierId: json['recommended_supplier_id']?.toString() ?? '',
      monthlySavingsVsWorst: (json['monthly_savings_vs_worst'] as num?)?.toDouble() ?? 0.0,
      insightSummaryEn: json['insight_summary_en']?.toString() ?? '',
      insightSummaryHi: json['insight_summary_hi']?.toString() ?? '',
      monthlyOperatingCostDelta: (json['monthly_operating_cost_delta'] as num?)?.toDouble() ?? 0.0,
    );
  }

  SupplierLandedCostItem? get recommendedSupplier {
    try {
      return results.firstWhere((r) => r.supplierId == recommendedSupplierId);
    } catch (_) {
      return results.isNotEmpty ? results.first : null;
    }
  }
}
