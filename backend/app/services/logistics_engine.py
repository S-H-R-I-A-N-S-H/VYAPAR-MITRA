from typing import Any, Dict, List, Optional
from app.schemas.geospatial import (
    DEFAULT_FREIGHT_RATES,
    FreightVehicleMode,
    SupplierCandidateInput,
    SupplierFreightEvaluationResponse,
    SupplierLandedCostItem,
    Coordinate,
)


class LogisticsEngine:
    """
    Deterministic calculation engine for rural freight economics and supplier landed costs.
    Applies strict reducing/landed cost math without LLM hallucinations.
    """

    @classmethod
    def evaluate_supplier_freight(
        cls,
        origin: Coordinate,
        suppliers: List[SupplierCandidateInput],
        matrix_results: List[Dict[str, Any]],
        vehicle_mode: FreightVehicleMode = FreightVehicleMode.PICKUP_TEMPO,
        freight_rate_per_km: Optional[float] = None,
        trips_per_month: int = 4,
        is_round_trip: bool = True,
    ) -> SupplierFreightEvaluationResponse:
        rate = (
            float(freight_rate_per_km)
            if freight_rate_per_km is not None and freight_rate_per_km > 0
            else DEFAULT_FREIGHT_RATES.get(vehicle_mode, 18.0)
        )

        matrix_lookup = {r["destination_id"]: r for r in matrix_results}
        evaluated_items: List[SupplierLandedCostItem] = []

        for sup in suppliers:
            mat = matrix_lookup.get(sup.id, {})
            dist_km = float(mat.get("distance_km", 0.0))
            duration = int(mat.get("duration_minutes", 0))
            is_real = bool(mat.get("is_real_mappls", False))

            billed_dist = round(dist_km * 2.0 if is_round_trip else dist_km, 1)
            trip_freight = round(billed_dist * rate, 2)
            moq = max(1.0, float(sup.min_order_quantity))
            freight_per_unit = round(trip_freight / moq, 2)
            effective_cost = round(sup.quoted_price_per_unit + freight_per_unit, 2)
            monthly_freight = round(trip_freight * trips_per_month, 2)

            evaluated_items.append(
                SupplierLandedCostItem(
                    supplier_id=sup.id,
                    supplier_name=sup.name,
                    distance_km=dist_km,
                    duration_minutes=duration,
                    quoted_price_per_unit=sup.quoted_price_per_unit,
                    unit_name=sup.unit_name,
                    min_order_quantity=moq,
                    trip_distance_billed_km=billed_dist,
                    trip_freight_cost=trip_freight,
                    freight_cost_per_unit=freight_per_unit,
                    effective_landed_cost=effective_cost,
                    monthly_freight_total=monthly_freight,
                    is_recommended=False,
                    is_real_mappls=is_real,
                )
            )

        if not evaluated_items:
            raise ValueError("Cannot evaluate empty supplier list")

        # Sort by effective landed cost ascending
        evaluated_items.sort(key=lambda x: x.effective_landed_cost)
        evaluated_items[0].is_recommended = True
        best = evaluated_items[0]
        worst = evaluated_items[-1]

        # Calculate monthly savings on total material + freight volume
        monthly_volume = best.min_order_quantity * trips_per_month
        best_monthly_total = best.effective_landed_cost * monthly_volume
        worst_monthly_total = worst.effective_landed_cost * monthly_volume
        monthly_savings = round(max(0.0, worst_monthly_total - best_monthly_total), 2)

        # Localized summaries
        if len(evaluated_items) > 1 and monthly_savings > 0:
            insight_en = (
                f"'{best.supplier_name}' provides the lowest landed cost at ₹{best.effective_landed_cost:.2f}/{best.unit_name} "
                f"(₹{best.quoted_price_per_unit:.2f} price + ₹{best.freight_cost_per_unit:.2f} freight). "
                f"Saves ₹{monthly_savings:,.0f}/month compared to higher-freight alternatives."
            )
            insight_hi = (
                f"'{best.supplier_name}' से कुल प्रभावी लागत सबसे कम ₹{best.effective_landed_cost:.2f}/{best.unit_name} है "
                f"(कच्चा माल ₹{best.quoted_price_per_unit:.2f} + ढुलाई ₹{best.freight_cost_per_unit:.2f})। "
                f"अधिक दूरी वाले विकल्प की तुलना में प्रति माह ₹{monthly_savings:,.0f} की शुद्ध बचत होगी।"
            )
        else:
            insight_en = (
                f"'{best.supplier_name}' effective landed cost is ₹{best.effective_landed_cost:.2f}/{best.unit_name} "
                f"including ₹{best.trip_freight_cost:.2f} per-trip transport."
            )
            insight_hi = (
                f"'{best.supplier_name}' की प्रभावी लागत ₹{best.effective_landed_cost:.2f}/{best.unit_name} है "
                f"(प्रति फेरा ₹{best.trip_freight_cost:.2f} वाहन व्यय सहित)।"
            )

        return SupplierFreightEvaluationResponse(
            origin=origin,
            vehicle_mode=vehicle_mode,
            freight_rate_per_km=rate,
            is_round_trip=is_round_trip,
            trips_per_month=trips_per_month,
            results=evaluated_items,
            recommended_supplier_id=best.supplier_id,
            monthly_savings_vs_worst=monthly_savings,
            insight_summary_en=insight_en,
            insight_summary_hi=insight_hi,
            monthly_operating_cost_delta=best.monthly_freight_total,
        )
