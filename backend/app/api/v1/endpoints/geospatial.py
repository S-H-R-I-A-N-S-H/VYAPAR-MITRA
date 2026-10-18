import logging
from typing import Any, Dict, List
from fastapi import APIRouter, Depends, HTTPException, status

from app.adapters.mappls_adapter import MapplsAdapter
from app.core.security import get_current_user
from app.schemas.common import APIResponse
from app.schemas.geospatial import (
    DistanceMatrixRequest,
    DistanceMatrixResponse,
    DistanceMatrixResultItem,
    SupplierFreightEvaluationRequest,
    SupplierFreightEvaluationResponse,
)
from app.services.logistics_engine import LogisticsEngine

logger = logging.getLogger(__name__)

router = APIRouter()
mappls_adapter = MapplsAdapter()


@router.post(
    "/distance-matrix",
    response_model=APIResponse[DistanceMatrixResponse],
    summary="Compute driving distance and duration matrix via Mappls / Rural Road Model",
)
async def compute_distance_matrix(
    payload: DistanceMatrixRequest,
) -> APIResponse[DistanceMatrixResponse]:
    """
    Computes driving distance (km) and duration (mins) from entrepreneur origin
    to specified destinations using Mappls REST API with deterministic rural road circuity fallback.
    """
    try:
        dest_dicts = [
            {
                "id": d.id,
                "name": d.name,
                "latitude": d.latitude,
                "longitude": d.longitude,
            }
            for d in payload.destinations
        ]

        matrix_raw = await mappls_adapter.get_distance_matrix(
            origin_lat=payload.origin.latitude,
            origin_lon=payload.origin.longitude,
            destinations=dest_dicts,
        )

        result_items = [
            DistanceMatrixResultItem(
                destination_id=r["destination_id"],
                destination_name=r["destination_name"],
                distance_km=r["distance_km"],
                duration_minutes=r["duration_minutes"],
                is_real_mappls=r.get("is_real_mappls", False),
            )
            for r in matrix_raw
        ]

        return APIResponse(
            success=True,
            data=DistanceMatrixResponse(origin=payload.origin, results=result_items),
            message=f"Calculated distance matrix for {len(result_items)} destinations",
        )
    except Exception as e:
        logger.error(f"Error computing distance matrix: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to calculate distance matrix: {str(e)}",
        )


@router.post(
    "/supplier-freight-evaluation",
    response_model=APIResponse[SupplierFreightEvaluationResponse],
    summary="Evaluate supplier landed costs and transport freight economics",
)
async def evaluate_supplier_freight(
    payload: SupplierFreightEvaluationRequest,
) -> APIResponse[SupplierFreightEvaluationResponse]:
    """
    Performs deterministic landed-cost analysis across candidate suppliers:
    quoted raw material price + vehicle freight cost per unit.
    Ranks suppliers and calculates exact monthly savings of choosing the optimal local partner.
    """
    try:
        dest_dicts = [
            {
                "id": s.id,
                "name": s.name,
                "latitude": s.latitude,
                "longitude": s.longitude,
            }
            for s in payload.suppliers
        ]

        matrix_raw = await mappls_adapter.get_distance_matrix(
            origin_lat=payload.origin.latitude,
            origin_lon=payload.origin.longitude,
            destinations=dest_dicts,
        )

        evaluation = LogisticsEngine.evaluate_supplier_freight(
            origin=payload.origin,
            suppliers=payload.suppliers,
            matrix_results=matrix_raw,
            vehicle_mode=payload.vehicle_mode,
            freight_rate_per_km=payload.freight_rate_per_km,
            trips_per_month=payload.trips_per_month,
            is_round_trip=payload.is_round_trip,
        )

        return APIResponse(
            success=True,
            data=evaluation,
            message="Supplier freight evaluation completed successfully",
        )
    except ValueError as ve:
        raise HTTPException(
            status_code=status.HTTP_422_UNPROCESSABLE_ENTITY,
            detail=str(ve),
        )
    except Exception as e:
        logger.error(f"Error evaluating supplier freight: {e}", exc_info=True)
        raise HTTPException(
            status_code=status.HTTP_500_INTERNAL_SERVER_ERROR,
            detail=f"Failed to evaluate supplier freight: {str(e)}",
        )
