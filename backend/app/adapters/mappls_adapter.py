from typing import Any, Dict, List, Optional
from app.core.config import settings


class MapplsAdapter:
    """
    Adapter for Mappls (MapmyIndia) Geocoding, Nearby Business Discovery, and Map services.
    Provides local sandbox mock fallback if credentials are not configured.
    """

    def __init__(self):
        self.client_id = settings.MAPPLS_CLIENT_ID
        self.client_secret = settings.MAPPLS_CLIENT_SECRET
        self.is_live = bool(self.client_id and self.client_secret)

    async def geocode(self, query: str) -> List[Dict[str, Any]]:
        """Resolves location text to coordinates."""
        if not self.is_live:
            return [
                {
                    "village": query,
                    "district": "Pune",
                    "state": "Maharashtra",
                    "pincode": "411001",
                    "latitude": 18.5204,
                    "longitude": 73.8567,
                }
            ]
        return []

    async def find_nearby_competitors(
        self, latitude: float, longitude: float, category: str, radius_km: float = 5.0
    ) -> List[Dict[str, Any]]:
        """Discovers registered businesses/competitors in the locality."""
        if not self.is_live:
            return [
                {"name": "Krishna Dairy Collection Center", "distance_km": 1.2, "category": category},
                {"name": "Shivkripa Agro Products", "distance_km": 2.8, "category": category},
            ]
        return []
