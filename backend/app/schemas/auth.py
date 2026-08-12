from datetime import datetime
from typing import Optional
from pydantic import BaseModel, EmailStr, Field
from app.models.user import UserRole

# Shared properties
class UserBase(BaseModel):
    email: EmailStr
    full_name: str
    phone: Optional[str] = None
    role: UserRole = UserRole.PATIENT

# Properties to receive on user registration
class UserRegister(UserBase):
    password: str = Field(..., min_length=6, description="Password must be at least 6 characters long")

# Properties to receive on login
class UserLogin(BaseModel):
    email: EmailStr
    password: str

# Properties to return to client on successful login
class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"

# Token payload content representation
class TokenPayload(BaseModel):
    sub: Optional[str] = None
    role: Optional[str] = None
    exp: Optional[int] = None

# Properties to return via API response
class UserResponse(UserBase):
    id: int
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True  # Pydantic v2 compatibility for ORM mapping (previously orm_mode = True)
