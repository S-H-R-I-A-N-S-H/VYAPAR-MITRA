from enum import Enum
from typing import List, Optional
from pydantic import BaseModel, Field


class FreightVehicleMode(str, Enum):
    TWO_WHEELER = "two_wheeler"
    AUTO_RICKSHAW = "auto_rickshaw"
    PICKUP_TEMPO = "pickup_tempo"
    TRACTOR_TROLLEY = "tractor_trolley"


# Standard benchmark rates in rural India (INR per km)
DEFAULT_FREIGHT_RATES = {
    FreightVehicleMode.TWO_WHEELER: 6.0,
    FreightVehicleMode.AUTO_RICKSHAW: 12.0,
    FreightVehicleMode.PICKUP_TEMPO: 18.0,
    FreightVehicleMode.TRACTOR_TROLLEY: 25.0,
}


class Coordinate(BaseModel):
    latitude: float = Field(..., ge=-90.0, le=90.0, description="Latitude in decimal degrees")
    longitude: float = Field(..., ge=-180.0, le=180.0, description="Longitude in decimal degrees")
    label: Optional[str] = Field(default=None, description="Optional name or landmark")


class DistanceMatrixDestination(BaseModel):
    id: str = Field(..., min_length=1, description="Unique identifier for destination")
    name: str = Field(..., min_length=1, description="Destination name or supplier label")
    latitude: float = Field(..., ge=-90.0, le=90.0)
    longitude: float = Field(..., ge=-180.0, le=180.0)


class DistanceMatrixRequest(BaseModel):
    origin: Coordinate = Field(..., description="Starting point / entrepreneur site")
    destinations: List[DistanceMatrixDestination] = Field(
        ..., min_length=1, max_length=50, description="List of destination locations"
    )


class DistanceMatrixResultItem(BaseModel):
    destination_id: str
    destination_name: str
    distance_km: float = Field(..., ge=0.0)
    duration_minutes: int = Field(..., ge=0)
    is_real_mappls: bool = Field(default=False)


class DistanceMatrixResponse(BaseModel):
    origin: Coordinate
    results: List[DistanceMatrixResultItem]


class SupplierCandidateInput(BaseModel):
    id: str = Field(..., min_length=1)
    name: str = Field(..., min_length=1)
    latitude: float = Field(..., ge=-90.0, le=90.0)
    longitude: float = Field(..., ge=-180.0, le=180.0)
    quoted_price_per_unit: float = Field(..., gt=0.0, description="Quoted unit price in INR")
    unit_name: str = Field(default="kg", description="Unit of measurement (e.g., kg, liter, bag)")
    min_order_quantity: float = Field(
        default=100.0, gt=0.0, description="Batch quantity procured per trip"
    )


class SupplierFreightEvaluationRequest(BaseModel):
    origin: Coordinate
    suppliers: List[SupplierCandidateInput] = Field(..., min_length=1, max_length=20)
    vehicle_mode: FreightVehicleMode = Field(default=FreightVehicleMode.PICKUP_TEMPO)
    freight_rate_per_km: Optional[float] = Field(
        default=None, gt=0.0, description="Optional custom freight rate (INR/km)"
    )
    trips_per_month: int = Field(default=4, ge=1, le=100, description="Estimated supply trips per month")
    is_round_trip: bool = Field(
        default=True, description="Whether transport charges round trip distance"
    )


class SupplierLandedCostItem(BaseModel):
    supplier_id: str
    supplier_name: str
    distance_km: float
    duration_minutes: int
    quoted_price_per_unit: float
    unit_name: str
    min_order_quantity: float
    trip_distance_billed_km: float
    trip_freight_cost: float
    freight_cost_per_unit: float
    effective_landed_cost: float
    monthly_freight_total: float
    is_recommended: bool
    is_real_mappls: bool


class SupplierFreightEvaluationResponse(BaseModel):
    origin: Coordinate
    vehicle_mode: FreightVehicleMode
    freight_rate_per_km: float
    is_round_trip: bool
    trips_per_month: int
    results: List[SupplierLandedCostItem]
    recommended_supplier_id: str
    monthly_savings_vs_worst: float
    insight_summary_en: str
    insight_summary_hi: str
    monthly_operating_cost_delta: float
