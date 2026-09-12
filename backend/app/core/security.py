from typing import Optional
from fastapi import Depends, Header
from app.core.config import settings
from app.core.errors import UnauthorizedAccessException


async def get_current_user_id(
    authorization: Optional[str] = Header(None, description="Bearer <Supabase JWT>"),
) -> str:
    """
    Validates the Supabase JWT access token and extracts the authenticated user ID.
    In development mode without configured Supabase credentials, supports mock auth for local verification.
    """
    if not authorization:
        raise UnauthorizedAccessException("Missing Authorization header.")

    scheme, _, token = authorization.partition(" ")
    if scheme.lower() != "bearer" or not token:
        raise UnauthorizedAccessException("Authorization header must follow 'Bearer <token>' format.")

    # In development mode with placeholder secrets, allow dev tokens for mock validation
    if settings.ENVIRONMENT == "development" and token.startswith("mock-user-"):
        return token.replace("mock-user-", "")

    # Production / standard verification path:
    try:
        from jose import jwt, JWTError

        if not settings.SUPABASE_JWT_SECRET:
            # Fallback for dev mode
            if settings.ENVIRONMENT == "development":
                return "dev-user-default"
            raise UnauthorizedAccessException("JWT secret is not configured on the server.")

        payload = jwt.decode(
            token,
            settings.SUPABASE_JWT_SECRET,
            algorithms=["HS256"],
            options={"verify_aud": False},
        )
        user_id: Optional[str] = payload.get("sub")
        if not user_id:
            raise UnauthorizedAccessException("Token payload does not contain a valid user identifier ('sub').")
        return user_id
    except JWTError as e:
        raise UnauthorizedAccessException(f"Token validation failed: {str(e)}")
