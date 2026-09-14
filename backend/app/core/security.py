from typing import Any, Dict, Optional
from fastapi import Header
from pydantic import BaseModel, Field
from app.core.config import settings
from app.core.errors import UnauthorizedAccessException

DEFAULT_DEV_JWT_SECRET = "test_supabase_jwt_secret_dev_key_32bytes_long"


class AuthenticatedUser(BaseModel):
    """Represents a cryptographically verified user session."""
    user_id: str
    email: Optional[str] = None
    role: str = "authenticated"
    claims: Dict[str, Any] = Field(default_factory=dict)

    def get(self, key: str, default: Any = None) -> Any:
        if key in ("sub", "id", "user_id"):
            return self.user_id
        if key == "email":
            return self.email
        if key == "role":
            return self.role
        if key in self.claims:
            return self.claims[key]
        return getattr(self, key, default)

    def __getitem__(self, key: str) -> Any:
        val = self.get(key)
        if val is None and key not in ("sub", "id", "user_id", "email", "role"):
            raise KeyError(key)
        return val


async def get_current_user(
    authorization: Optional[str] = Header(None, description="Bearer <Supabase JWT>"),
) -> AuthenticatedUser:
    """
    Validates the Supabase JWT access token and returns an AuthenticatedUser model.
    Enforces expiration check, signature integrity, and dev-mock scoping.
    """
    if not authorization:
        if settings.ENVIRONMENT == "development" and getattr(settings, "DEV_ALLOW_ANONYMOUS", False):
            return AuthenticatedUser(
                user_id="dev-user-default",
                email="dev-user-default@vyaparmitra.dev",
                role="authenticated",
                claims={"sub": "dev-user-default", "mock": True},
            )
        raise UnauthorizedAccessException("Missing Authorization header.")

    scheme, _, token = authorization.partition(" ")
    if scheme.lower() != "bearer" or not token:
        if settings.ENVIRONMENT == "development" and getattr(settings, "DEV_ALLOW_ANONYMOUS", False):
            return AuthenticatedUser(
                user_id="dev-user-default",
                email="dev-user-default@vyaparmitra.dev",
                role="authenticated",
                claims={"sub": "dev-user-default", "mock": True},
            )
        raise UnauthorizedAccessException("Authorization header must follow 'Bearer <token>' format.")

    # Mock dev tokens are strictly restricted to development environments
    if token.startswith("mock-user-"):
        if settings.ENVIRONMENT == "development":
            mock_id = token.replace("mock-user-", "")
            return AuthenticatedUser(
                user_id=mock_id,
                email=f"{mock_id}@vyaparmitra.dev",
                role="authenticated",
                claims={"sub": mock_id, "mock": True},
            )
        raise UnauthorizedAccessException("Mock tokens are prohibited outside development environment.")

    jwt_secret = settings.SUPABASE_JWT_SECRET or DEFAULT_DEV_JWT_SECRET

    try:
        from jose import jwt, JWTError, ExpiredSignatureError

        payload = jwt.decode(
            token,
            jwt_secret,
            algorithms=["HS256"],
            options={"verify_aud": False},
        )

        user_id: Optional[str] = payload.get("sub") or payload.get("id")
        if not user_id:
            raise UnauthorizedAccessException("Token payload does not contain a valid user identifier ('sub').")

        return AuthenticatedUser(
            user_id=user_id,
            email=payload.get("email"),
            role=payload.get("role", "authenticated"),
            claims=payload,
        )
    except ExpiredSignatureError:
        raise UnauthorizedAccessException("Token has expired. Please re-authenticate.")
    except JWTError as e:
        raise UnauthorizedAccessException(f"Token validation failed: {str(e)}")


async def get_current_user_id(
    authorization: Optional[str] = Header(None, description="Bearer <Supabase JWT>"),
) -> str:
    """
    Convenience dependency returning just the verified user UUID string.
    """
    user = await get_current_user(authorization)
    return user.user_id
