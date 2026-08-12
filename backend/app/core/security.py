from datetime import datetime, timedelta
from typing import Any, Union
from jose import jwt
from passlib.context import CryptContext
from app.core.config import settings

# Password hashing configuration using bcrypt scheme
pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")

# JWT configuration constants
ALGORITHM = "HS256"

def _truncate_password(password: str) -> str:
    """Ensure password byte length does not exceed bcrypt's 72-byte limit."""
    if not password:
        return ""
    encoded = password.encode("utf-8")
    if len(encoded) > 72:
        return encoded[:72].decode("utf-8", errors="ignore")
    return password

def verify_password(plain_password: str, hashed_password: str) -> bool:
    """Verify a plain text password against its hash."""
    if not plain_password or not hashed_password:
        return False
    safe_password = _truncate_password(plain_password)
    try:
        return pwd_context.verify(safe_password, hashed_password)
    except Exception:
        return False

def get_password_hash(password: str) -> str:
    """Generate a bcrypt hash of the password."""
    safe_password = _truncate_password(password)
    return pwd_context.hash(safe_password)

def create_access_token(subject: Union[str, Any], role: str, expires_delta: timedelta = None) -> str:
    """Create a signed JWT access token containing subject (email) and user role."""
    if expires_delta:
        expire = datetime.utcnow() + expires_delta
    else:
        expire = datetime.utcnow() + timedelta(minutes=settings.ACCESS_TOKEN_EXPIRE_MINUTES)
    
    to_encode = {
        "exp": expire,
        "sub": str(subject),
        "role": role
    }
    encoded_jwt = jwt.encode(to_encode, settings.SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

def decode_access_token(token: str) -> dict:
    """Decode and validate a JWT access token."""
    try:
        decoded_token = jwt.decode(token, settings.SECRET_KEY, algorithms=[ALGORITHM])
        # Return claims if token has not expired
        return decoded_token if datetime.utcfromtimestamp(decoded_token["exp"]) >= datetime.utcnow() else None
    except Exception:
        return None
