import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.schemas.geospatial import (
    DEFAULT_FREIGHT_RATES,
    FreightVehicleMode,
    SupplierCandidateInput,
    Coordinate,
)
from app.services.logistics_engine import LogisticsEngine

client = TestClient(app)


def test_distance_matrix_endpoint():
    payload = {
        "origin": {"latitude": 22.9772, "longitude": 75.8078, "label": "Sanwer Site"},
        "destinations": [
            {
                "id": "sup-001",
                "name": "Malwa Agro Center",
                "latitude": 22.9950,
                "longitude": 75.8200,
            },
            {
                "id": "sup-002",
                "name": "Ujjain Feed Mandi",
                "latitude": 23.1765,
                "longitude": 75.7885,
            },
        ],
    }
    resp = client.post("/api/v1/geospatial/distance-matrix", json=payload)
    assert resp.status_code == 200
    data = resp.json()
    assert data["success"] is True
    results = data["data"]["results"]
    assert len(results) == 2
    assert results[0]["destination_id"] == "sup-001"
    assert results[0]["distance_km"] > 0.0
    assert results[0]["duration_minutes"] >= 1
    assert results[1]["destination_id"] == "sup-002"
    # Ujjain is farther than local Sanwer dest
    assert results[1]["distance_km"] > results[0]["distance_km"]


def test_distance_matrix_zero_distance():
    payload = {
        "origin": {"latitude": 22.9772, "longitude": 75.8078},
        "destinations": [
            {
                "id": "same-loc",
                "name": "Adjacent Godown",
                "latitude": 22.9772,
                "longitude": 75.8078,
            }
        ],
    }
    resp = client.post("/api/v1/geospatial/distance-matrix", json=payload)
    assert resp.status_code == 200
    results = resp.json()["data"]["results"]
    assert results[0]["distance_km"] == 0.0
    assert results[0]["duration_minutes"] == 0


def test_supplier_freight_evaluation_landed_cost_reversal():
    """
    Core Product Scenario:
    Supplier A quotes lower price (₹90.00/unit) but is 20 km away.
    Supplier B quotes higher price (₹95.00/unit) but is only 3 km away.
    After vehicle freight, Supplier B must have LOWER effective landed cost!
    """
    origin = {"latitude": 22.9772, "longitude": 75.8078}  # Sanwer
    # Supplier A: far away (~20 km)
    sup_a = {
        "id": "sup-far-cheap",
        "name": "Distant Wholesale Feed Co",
        "latitude": 23.1500,
        "longitude": 75.8078,
        "quoted_price_per_unit": 90.0,
        "unit_name": "kg",
        "min_order_quantity": 100.0,
    }
    # Supplier B: nearby (~3 km)
    sup_b = {
        "id": "sup-near-costly",
        "name": "Sanwer Local Agro Store",
        "latitude": 22.9950,
        "longitude": 75.8150,
        "quoted_price_per_unit": 95.0,
        "unit_name": "kg",
        "min_order_quantity": 100.0,
    }

    payload = {
        "origin": origin,
        "suppliers": [sup_a, sup_b],
        "vehicle_mode": "pickup_tempo",  # ₹18/km
        "freight_rate_per_km": 18.0,
        "trips_per_month": 4,
        "is_round_trip": True,
    }

    resp = client.post("/api/v1/geospatial/supplier-freight-evaluation", json=payload)
    assert resp.status_code == 200
    res_data = resp.json()["data"]

    # Recommended must be the local supplier despite higher initial quote
    assert res_data["recommended_supplier_id"] == "sup-near-costly"
    assert res_data["monthly_savings_vs_worst"] > 0
    assert "Sanwer Local Agro Store" in res_data["insight_summary_en"]
    assert "Sanwer Local Agro Store" in res_data["insight_summary_hi"]

    items_by_id = {i["supplier_id"]: i for i in res_data["results"]}
    near_item = items_by_id["sup-near-costly"]
    far_item = items_by_id["sup-far-cheap"]

    assert near_item["is_recommended"] is True
    assert far_item["is_recommended"] is False
    assert near_item["effective_landed_cost"] < far_item["effective_landed_cost"]
    assert res_data["monthly_operating_cost_delta"] == near_item["monthly_freight_total"]


def test_supplier_freight_evaluation_validation():
    # Empty suppliers list must be rejected
    payload = {
        "origin": {"latitude": 22.9772, "longitude": 75.8078},
        "suppliers": [],
    }
    resp = client.post("/api/v1/geospatial/supplier-freight-evaluation", json=payload)
    assert resp.status_code == 422


def test_logistics_engine_pure_math():
    origin = Coordinate(latitude=22.0, longitude=75.0)
    suppliers = [
        SupplierCandidateInput(
            id="s1",
            name="Supplier 1",
            latitude=22.1,
            longitude=75.1,
            quoted_price_per_unit=100.0,
            unit_name="kg",
            min_order_quantity=50.0,
        )
    ]
    matrix = [
        {
            "destination_id": "s1",
            "destination_name": "Supplier 1",
            "distance_km": 10.0,
            "duration_minutes": 20,
            "is_real_mappls": False,
        }
    ]

    res = LogisticsEngine.evaluate_supplier_freight(
        origin=origin,
        suppliers=suppliers,
        matrix_results=matrix,
        vehicle_mode=FreightVehicleMode.AUTO_RICKSHAW,  # ₹12/km
        trips_per_month=4,
        is_round_trip=True,
    )

    # 10 km round trip = 20 km. At ₹12/km = ₹240 trip freight.
    # ₹240 / 50 kg MOQ = ₹4.80 freight per unit.
    # Effective landed = ₹100 + ₹4.80 = ₹104.80.
    item = res.results[0]
    assert item.trip_distance_billed_km == 20.0
    assert item.trip_freight_cost == 240.0
    assert item.freight_cost_per_unit == 4.80
    assert item.effective_landed_cost == 104.80
    assert item.monthly_freight_total == 240.0 * 4 == 960.0
    assert res.monthly_operating_cost_delta == 960.0
