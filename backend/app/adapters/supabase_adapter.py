import time
from typing import Any, Dict, List, Optional
from app.core.config import settings


class SupabaseAdapter:
    """
    Adapter for Supabase PostgreSQL, Auth, and Storage.
    Provides verified database access, ping verification, and graceful fallback.
    """

    def __init__(self):
        self.url = settings.SUPABASE_URL
        self.key = settings.SUPABASE_KEY
        self.service_role_key = settings.SUPABASE_SERVICE_ROLE_KEY
        self._client = None
        self._admin_client = None

    @property
    def client(self):
        if self._client is None and self.url and self.key:
            try:
                from supabase import create_client
                self._client = create_client(self.url, self.key)
            except Exception:
                self._client = None
        return self._client

    @property
    def admin_client(self):
        if self._admin_client is None and self.url and self.service_role_key:
            try:
                from supabase import create_client
                self._admin_client = create_client(self.url, self.service_role_key)
            except Exception:
                self._admin_client = None
        return self._admin_client

    def check_connection(self) -> Dict[str, Any]:
        """
        Executes a lightweight query against Supabase to verify live connectivity and measure latency.
        Never raises exceptions; returns clean status dictionary.
        """
        if not self.url or not self.key:
            return {
                "status": "unconfigured",
                "latency_ms": None,
                "error": "Supabase credentials not configured in environment.",
            }

        client = self.client
        if client is None:
            return {
                "status": "disconnected",
                "latency_ms": None,
                "error": "Failed to initialize Supabase client.",
            }

        start_time = time.perf_counter()
        try:
            # Query the schemes table (lightweight probe)
            client.table("schemes").select("id", count="exact").limit(1).execute()
            latency = round((time.perf_counter() - start_time) * 1000, 2)
            return {
                "status": "connected",
                "latency_ms": latency,
                "error": None,
            }
        except Exception as exc:
            return {
                "status": "disconnected",
                "latency_ms": None,
                "error": str(exc),
            }


# Singleton instance for application-wide use
supabase_adapter = SupabaseAdapter()
