from typing import Any, Dict, List, Optional
from app.core.config import settings


class SupabaseAdapter:
    """
    Adapter for Supabase PostgreSQL, Auth, and Storage.
    Provides data access and fallback in-memory simulation during local development.
    """

    def __init__(self):
        self.url = settings.SUPABASE_URL
        self.key = settings.SUPABASE_KEY
        self._client = None
        if self.url and self.key:
            try:
                from supabase import create_client

                self._client = create_client(self.url, self.key)
            except Exception:
                self._client = None

    @property
    def client(self):
        return self._client
