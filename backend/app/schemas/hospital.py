from typing import Optional
from datetime import datetime
from pydantic import BaseModel, EmailStr, Field, field_validator
from app.models.hospital import VerificationStatus, HospitalStatus

class HospitalCreate(BaseModel):
    name: str = Field(..., min_length=1, description="Hospital name must not be empty")
    address: str = Field(..., min_length=1, description="Address is required")
    city: str = Field("", description="City name")
    state: str = Field("", description="State name")
    postal_code: str = Field("", description="Postal code")
    phone: str = Field(..., min_length=1, description="Phone number is required")
    email: EmailStr = Field(..., description="Valid email address")
    latitude: float = Field(..., ge=-90.0, le=90.0, description="Latitude must be between -90 and 90")
    longitude: float = Field(..., ge=-180.0, le=180.0, description="Longitude must be between -180 and 180")
    emergency_available: bool = Field(True, description="Whether emergency services are available")

    @field_validator('name', 'address', 'phone')
    @classmethod
    def not_empty(cls, v: str) -> str:
        if not v or not v.strip():
            raise ValueError("Field cannot be empty or blank")
        return v.strip()

class HospitalUpdate(BaseModel):
    name: Optional[str] = None
    address: Optional[str] = None
    city: Optional[str] = None
    state: Optional[str] = None
    postal_code: Optional[str] = None
    phone: Optional[str] = None
    email: Optional[EmailStr] = None
    latitude: Optional[float] = Field(None, ge=-90.0, le=90.0)
    longitude: Optional[float] = Field(None, ge=-180.0, le=180.0)
    emergency_available: Optional[bool] = None

    @field_validator('name', 'address', 'phone')
    @classmethod
    def not_empty_optional(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and (not v or not v.strip()):
            raise ValueError("Field cannot be empty or blank")
        return v.strip() if v else v

class HospitalVerify(BaseModel):
    verification_status: VerificationStatus

class HospitalResponse(BaseModel):
    id: int
    name: str
    address: str
    city: str
    state: str
    postal_code: str
    phone: str
    email: str
    latitude: float
    longitude: float
    emergency_available: bool
    verification_status: VerificationStatus
    status: HospitalStatus
    admin_id: Optional[int] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
