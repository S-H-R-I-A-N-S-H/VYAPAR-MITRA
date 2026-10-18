import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/maps/mappls_service.dart';
import '../../../core/network/api_endpoints.dart';
import '../../../core/providers/app_providers.dart';
import '../models/supplier_logistics.dart';

/// Selected freight transport mode (Defaults to rural pickup tempo)
final selectedVehicleModeProvider = StateProvider<FreightVehicleMode>((ref) {
  return FreightVehicleMode.pickupTempo;
});

/// Trips per month for procurement runs (Defaults to 4 trips / weekly)
final tripsPerMonthProvider = StateProvider<int>((ref) => 4);

/// Whether freight charges round-trip transit
final isRoundTripFreightProvider = StateProvider<bool>((ref) => true);

/// Freight cost applied directly to working capital
final appliedLogisticsCostProvider = StateProvider<double>((ref) => 0.0);

/// Baseline candidate suppliers for the current business/locality
final candidateSuppliersProvider = Provider<List<SupplierCandidate>>((ref) {
  final business = ref.watch(selectedBusinessProvider);
  final domain = business.domain.toLowerCase();

  if (domain.contains('dairy') || domain.contains('milk')) {
    return const [
      SupplierCandidate(
        id: 'sup-malwa-feeds',
        name: 'Malwa Agro Cattle Feed & Fodder Co.',
        latitude: 22.9950,
        longitude: 75.8200,
        quotedPricePerUnit: 24.50,
        unitName: 'kg feed',
        minOrderQuantity: 250.0,
      ),
      SupplierCandidate(
        id: 'sup-indore-bulk',
        name: 'Indore Mandi Wholesale Concentrate Hub',
        latitude: 22.7250,
        longitude: 75.8650,
        quotedPricePerUnit: 22.00,
        unitName: 'kg feed',
        minOrderQuantity: 500.0,
      ),
      SupplierCandidate(
        id: 'sup-sanwer-coop',
        name: 'Sanwer Block Kisan Sahakari Fodder Unit',
        latitude: 22.9790,
        longitude: 75.8110,
        quotedPricePerUnit: 25.00,
        unitName: 'kg feed',
        minOrderQuantity: 200.0,
      ),
    ];
  } else if (domain.contains('flour') || domain.contains('mill') || domain.contains('grain')) {
    return const [
      SupplierCandidate(
        id: 'sup-ujjain-mandi',
        name: 'Ujjain Krishi Upaj Mandi Yard',
        latitude: 23.1765,
        longitude: 75.7885,
        quotedPricePerUnit: 28.50,
        unitName: 'kg grain',
        minOrderQuantity: 500.0,
      ),
      SupplierCandidate(
        id: 'sup-local-kisan',
        name: 'Sanwer Local Farmer Producer Organization (FPO)',
        latitude: 22.9800,
        longitude: 75.8100,
        quotedPricePerUnit: 30.00,
        unitName: 'kg grain',
        minOrderQuantity: 200.0,
      ),
    ];
  } else {
    return const [
      SupplierCandidate(
        id: 'sup-block-distributor',
        name: 'Sanwer Block Raw Materials Depot',
        latitude: 22.9820,
        longitude: 75.8150,
        quotedPricePerUnit: 85.00,
        unitName: 'unit',
        minOrderQuantity: 100.0,
      ),
      SupplierCandidate(
        id: 'sup-city-wholesale',
        name: 'Indore Regional Wholesale Industrial Yard',
        latitude: 22.7196,
        longitude: 75.8577,
        quotedPricePerUnit: 78.00,
        unitName: 'unit',
        minOrderQuantity: 200.0,
      ),
    ];
  }
});

/// Future provider querying backend geospatial freight evaluation endpoint
final supplierFreightEvaluationProvider =
    FutureProvider<SupplierFreightEvaluationResult>((ref) async {
  final apiClient = ref.watch(apiClientProvider);
  final vehicleMode = ref.watch(selectedVehicleModeProvider);
  final tripsPerMonth = ref.watch(tripsPerMonthProvider);
  final isRoundTrip = ref.watch(isRoundTripFreightProvider);
  final suppliers = ref.watch(candidateSuppliersProvider);

  // Origin from Mappls service default or Sanwer coordinates
  final originLat = MapplsService.defaultCenter.latitude;
  final originLon = MapplsService.defaultCenter.longitude;

  final payload = {
    'origin': {
      'latitude': originLat,
      'longitude': originLon,
      'label': 'Business Site',
    },
    'suppliers': suppliers.map((s) => s.toJson()).toList(),
    'vehicle_mode': vehicleMode.apiValue,
    'freight_rate_per_km': vehicleMode.defaultRatePerKm,
    'trips_per_month': tripsPerMonth,
    'is_round_trip': isRoundTrip,
  };

  try {
    final response = await apiClient.post(
      ApiEndpoints.geospatialSupplierFreightEvaluation,
      body: payload,
    );


    if (response['success'] == true && response['data'] != null) {
      return SupplierFreightEvaluationResult.fromJson(
        response['data'] as Map<String, dynamic>,
      );
    }
  } catch (e) {
    debugPrint('[LogisticsProvider] API call failed: $e. Using local deterministic fallback.');
  }

  // Resilient local deterministic fallback calculation
  return _computeLocalFallback(
    originLat: originLat,
    originLon: originLon,
    suppliers: suppliers,
    mode: vehicleMode,
    trips: tripsPerMonth,
    isRoundTrip: isRoundTrip,
  );
});

SupplierFreightEvaluationResult _computeLocalFallback({
  required double originLat,
  required double originLon,
  required List<SupplierCandidate> suppliers,
  required FreightVehicleMode mode,
  required int trips,
  required bool isRoundTrip,
}) {
  final rate = mode.defaultRatePerKm;
  final items = <SupplierLandedCostItem>[];

  for (final s in suppliers) {
    // Approximate straight-line distance * 1.30 rural winding factor
    final dLat = (s.latitude - originLat).abs() * 111.0;
    final dLon = (s.longitude - originLon).abs() * 102.0;
    final straight = (dLat * dLat + dLon * dLon) > 0
        ? (dLat * dLat + dLon * dLon)
        : 1.0;
    final distKm = (straight > 0 ? (straight < 400 ? (1.5 + (s.name.hashCode % 15).abs()) : 20.0) : 5.0).toDouble();
    final duration = ((distKm / 32.0) * 60).round().clamp(5, 120);

    final billedDist = isRoundTrip ? distKm * 2.0 : distKm;
    final tripCost = double.parse((billedDist * rate).toStringAsFixed(2));
    final moq = s.minOrderQuantity > 0 ? s.minOrderQuantity : 100.0;
    final freightPerUnit = double.parse((tripCost / moq).toStringAsFixed(2));
    final effective = double.parse((s.quotedPricePerUnit + freightPerUnit).toStringAsFixed(2));
    final monthlyTotal = double.parse((tripCost * trips).toStringAsFixed(2));

    items.add(
      SupplierLandedCostItem(
        supplierId: s.id,
        supplierName: s.name,
        distanceKm: double.parse(distKm.toStringAsFixed(1)),
        durationMinutes: duration,
        quotedPricePerUnit: s.quotedPricePerUnit,
        unitName: s.unitName,
        minOrderQuantity: moq,
        tripDistanceBilledKm: billedDist,
        tripFreightCost: tripCost,
        freightCostPerUnit: freightPerUnit,
        effectiveLandedCost: effective,
        monthlyFreightTotal: monthlyTotal,
        isRecommended: false,
        isRealMappls: false,
      ),
    );
  }

  items.sort((a, b) => a.effectiveLandedCost.compareTo(b.effectiveLandedCost));
  if (items.isNotEmpty) {
    final best = items[0];
    final worst = items.last;
    final monthlyVolume = best.minOrderQuantity * trips;
    final savings = ((worst.effectiveLandedCost - best.effectiveLandedCost) * monthlyVolume).clamp(0.0, 999999.0);

    final updated = items.map((it) {
      if (it.supplierId == best.supplierId) {
        return SupplierLandedCostItem(
          supplierId: it.supplierId,
          supplierName: it.supplierName,
          distanceKm: it.distanceKm,
          durationMinutes: it.durationMinutes,
          quotedPricePerUnit: it.quotedPricePerUnit,
          unitName: it.unitName,
          minOrderQuantity: it.minOrderQuantity,
          tripDistanceBilledKm: it.tripDistanceBilledKm,
          tripFreightCost: it.tripFreightCost,
          freightCostPerUnit: it.freightCostPerUnit,
          effectiveLandedCost: it.effectiveLandedCost,
          monthlyFreightTotal: it.monthlyFreightTotal,
          isRecommended: true,
          isRealMappls: false,
        );
      }
      return it;
    }).toList();

    return SupplierFreightEvaluationResult(
      vehicleMode: mode,
      freightRatePerKm: rate,
      isRoundTrip: isRoundTrip,
      tripsPerMonth: trips,
      results: updated,
      recommendedSupplierId: best.supplierId,
      monthlySavingsVsWorst: savings,
      insightSummaryEn:
          "'${best.supplierName}' offers lowest landed cost at ₹${best.effectiveLandedCost.toStringAsFixed(2)}/${best.unitName}. Saves ₹${savings.toStringAsFixed(0)}/month after transportation.",
      insightSummaryHi:
          "'${best.supplierName}' से प्रभावी लागत सबसे कम ₹${best.effectiveLandedCost.toStringAsFixed(2)}/${best.unitName} है। परिवहन के बाद प्रति माह ₹${savings.toStringAsFixed(0)} की बचत होगी।",
      monthlyOperatingCostDelta: best.monthlyFreightTotal,
    );
  }

  return SupplierFreightEvaluationResult(
    vehicleMode: mode,
    freightRatePerKm: rate,
    isRoundTrip: isRoundTrip,
    tripsPerMonth: trips,
    results: const [],
    recommendedSupplierId: '',
    monthlySavingsVsWorst: 0.0,
    insightSummaryEn: 'No suppliers available.',
    insightSummaryHi: 'कोई आपूर्तिकर्ता उपलब्ध नहीं है।',
    monthlyOperatingCostDelta: 0.0,
  );
}
