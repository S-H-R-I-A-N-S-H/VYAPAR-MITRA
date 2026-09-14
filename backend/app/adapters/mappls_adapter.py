from datetime import datetime
import logging
import time
from typing import Any, Dict, List, Optional
import httpx

from app.core.config import settings

logger = logging.getLogger(__name__)


class MapplsAdapter:
    """
    Adapter for Mappls (MapmyIndia) Geocoding, Nearby Business Discovery, and Map services.
    Handles OAuth 2.0 client credential token exchange, token caching, and resilient sandbox fallback.
    """

    OAUTH_URL = "https://outpost.mappls.com/api/security/oauth/token"
    GEOCODE_URL = "https://atlas.mappls.com/api/places/geocode"
    NEARBY_URL = "https://atlas.mappls.com/api/places/nearby/json"

    def __init__(self):
        self.client_id = settings.MAPPLS_CLIENT_ID or ""
        self.client_secret = settings.MAPPLS_CLIENT_SECRET or ""
        self.is_live = bool(self.client_id.strip() and self.client_secret.strip())
        self._cached_token: Optional[str] = None
        self._token_expiry: float = 0.0

    async def _get_access_token(self) -> Optional[str]:
        """Fetches or returns cached OAuth 2.0 access token."""
        if not self.is_live:
            return None

        # Return cached token if valid for at least 60 more seconds
        if self._cached_token and time.time() < self._token_expiry - 60:
            return self._cached_token

        try:
            async with httpx.AsyncClient(timeout=8.0) as client:
                resp = await client.post(
                    self.OAUTH_URL,
                    data={
                        "grant_type": "client_credentials",
                        "client_id": self.client_id,
                        "client_secret": self.client_secret,
                    },
                    headers={"Content-Type": "application/x-www-form-urlencoded"},
                )
                if resp.status_code == 200:
                    data = resp.json()
                    self._cached_token = data.get("access_token")
                    expires_in = int(data.get("expires_in", 3600))
                    self._token_expiry = time.time() + expires_in
                    logger.info("Successfully refreshed Mappls OAuth token.")
                    return self._cached_token
                else:
                    logger.warning(
                        f"Mappls OAuth token request returned HTTP {resp.status_code}: {resp.text}"
                    )
                    return None
        except Exception as e:
            logger.warning(f"Failed to obtain Mappls access token: {e}")
            return None

    # Known block/district coordinates for Madhya Pradesh (offline fallback)
    _MP_COORDS: Dict[str, tuple] = {
        "sanwer": (22.9772, 75.8078),
        "sawer": (22.9772, 75.8078),
        "indore": (22.7196, 75.8577),
        "bhopal": (23.2599, 77.4126),
        "ujjain": (23.1765, 75.7885),
        "dewas": (22.9676, 76.0534),
        "huzur": (23.1910, 77.4750),
        "sehore": (23.2013, 77.0849),
        "mandsaur": (24.0728, 75.0701),
        "ratlam": (23.3315, 75.0367),
        "neemuch": (24.4747, 74.8699),
        "gwalior": (26.2183, 78.1828),
        "jabalpur": (23.1815, 79.9864),
    }

    async def geocode(self, query: str) -> List[Dict[str, Any]]:
        """
        Resolves location text (village, block, district) to geographical coordinates.
        Falls back to realistic sandbox data if offline or on network failure.
        """
        cleaned_query = (query or "").strip()
        if not cleaned_query:
            return []

        if self.is_live:
            token = await self._get_access_token()
            if token:
                try:
                    async with httpx.AsyncClient(timeout=8.0) as client:
                        # Use Mappls geocode to get address text
                        resp = await client.get(
                            self.GEOCODE_URL,
                            params={"address": cleaned_query},
                            headers={"Authorization": f"Bearer {token}"},
                        )
                        if resp.status_code == 200:
                            data = resp.json()
                            cop = data.get("copResults")
                            if isinstance(cop, list) and cop:
                                cop = cop[0]
                            if cop and isinstance(cop, dict):
                                district_raw = cop.get("district") or cop.get("city") or "Indore"
                                district = district_raw.replace(" District", "").strip()
                                sub_dist = cop.get("subDistrict") or cop.get("village") or cleaned_query
                                state = cop.get("state") or "Madhya Pradesh"
                                pincode = str(cop.get("pincode") or "")

                                # Check direct coordinates first
                                lat, lon = None, None
                                if cop.get("latitude") is not None and cop.get("longitude") is not None:
                                    try:
                                        lat = float(cop["latitude"])
                                        lon = float(cop["longitude"])
                                    except (ValueError, TypeError):
                                        lat, lon = None, None

                                if lat is None or lon is None:
                                    # Resolve lat/lon: check known table first
                                    lat, lon = 22.9772, 75.8078  # Sanwer default
                                    for key, coords in self._MP_COORDS.items():
                                        if key in sub_dist.lower() or key in cleaned_query.lower():
                                            lat, lon = coords
                                            break
                                    else:
                                        # Fallback: search nearby with location name
                                        try:
                                            s_resp = await client.get(
                                                "https://atlas.mappls.com/api/places/search/json",
                                                params={"query": sub_dist, "radius": "50000"},
                                                headers={"Authorization": f"Bearer {token}"},
                                            )
                                            if s_resp.status_code == 200:
                                                locs = s_resp.json().get("suggestedLocations", [])
                                                if locs:
                                                    # Use nearby endpoint to get coords for the eLoc
                                                    eloc = locs[0].get("eLoc", "")
                                                    if eloc:
                                                        n_resp = await client.get(
                                                            self.NEARBY_URL,
                                                            params={"keywords": "area", "refLocation": eloc, "radius": 100},
                                                            headers={"Authorization": f"Bearer {token}"},
                                                        )
                                                        if n_resp.status_code == 200:
                                                            nlocs = n_resp.json().get("suggestedLocations", [])
                                                            if nlocs and nlocs[0].get("latitude"):
                                                                lat = float(nlocs[0]["latitude"])
                                                                lon = float(nlocs[0]["longitude"])
                                        except Exception:
                                            pass

                                return [{
                                    "village": sub_dist,
                                    "district": district,
                                    "state": state,
                                    "pincode": pincode,
                                    "latitude": lat,
                                    "longitude": lon,
                                    "formatted_address": cop.get("formattedAddress") or cleaned_query,
                                }]
                        else:
                            logger.warning(f"Mappls geocode returned HTTP {resp.status_code}")
                except Exception as e:
                    logger.warning(f"Mappls geocode network error: {e}. Degrading to sandbox.")

        # Sandbox fallback
        return [
            {
                "village": cleaned_query,
                "district": "Pune",
                "state": "Maharashtra",
                "pincode": "411001",
                "latitude": 18.5204,
                "longitude": 73.8567,
                "formatted_address": f"{cleaned_query}, Pune, Maharashtra, 411001",
            }
        ]

    async def find_nearby_competitors(
        self, latitude: float, longitude: float, category: str, radius_km: float = 5.0
    ) -> List[Dict[str, Any]]:
        """
        Discovers registered businesses/competitors within the specified radius.
        Returns normalized list of competitor items.
        """
        radius_meters = int(radius_km * 1000)

        if self.is_live:
            token = await self._get_access_token()
            if token:
                try:
                    async with httpx.AsyncClient(timeout=8.0) as client:
                        resp = await client.get(
                            self.NEARBY_URL,
                            params={
                                "keywords": category,
                                "refLocation": f"{latitude},{longitude}",
                                "radius": radius_meters,
                            },
                            headers={"Authorization": f"Bearer {token}"},
                        )
                        if resp.status_code == 200:
                            data = resp.json()
                            locations = data.get("suggestedLocations", [])
                            competitors: List[Dict[str, Any]] = []
                            for loc in locations:
                                dist_meters = float(loc.get("distance", 0.0))
                                competitors.append({
                                    "name": loc.get("placeName", f"{category} Enterprise"),
                                    "distance_km": round(dist_meters / 1000.0, 2),
                                    "category": category,
                                    "address": loc.get("placeAddress", ""),
                                })
                            return competitors
                        else:
                            logger.warning(f"Mappls nearby search returned HTTP {resp.status_code}")
                except Exception as e:
                    logger.warning(f"Mappls nearby search error: {e}. Degrading to sandbox.")

        # Realistic rural sandbox competitor data based on category
        cat_lower = category.lower()
        if "dairy" in cat_lower or "milk" in cat_lower:
            return [
                {"name": "Krishna Dairy Collection Center", "distance_km": 1.2, "category": category, "address": "Station Rd, Near Gram Panchayat"},
                {"name": "Shivkripa Agro & Milk Products", "distance_km": 2.8, "category": category, "address": "State Highway 10, MIDC"},
                {"name": "Govind Milk Producer Cooperative", "distance_km": 4.1, "category": category, "address": "Market Yard Gate No. 2"},
            ]
        elif "flour" in cat_lower or "mill" in cat_lower or "atta" in cat_lower:
            return [
                {"name": "Shree Ganesh Chakki & Mini Flour Mill", "distance_km": 0.8, "category": category, "address": "Main Bazar Peth"},
                {"name": "Kisan Grain Processing Center", "distance_km": 3.4, "category": category, "address": "APMC Mandi Yard"},
            ]
        else:
            return [
                {"name": f"{category.title()} Enterprise Hub", "distance_km": 1.5, "category": category, "address": "Gram Panchayat Chowk"},
                {"name": f"Rural {category.title()} Center", "distance_km": 3.2, "category": category, "address": "Bazar Peth"},
            ]
