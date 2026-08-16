from typing import Optional, List
from datetime import datetime
from pydantic import BaseModel, EmailStr, Field, field_validator
from app.models.hospital import VerificationStatus, HospitalStatus, BedStatus, BedType, WardStatus


# ──────────────────────────────────────────────────────────────
# Hospital schemas
# ──────────────────────────────────────────────────────────────

class HospitalCreate(BaseModel):
    name: str = Field(..., min_length=1, description="Hospital name must not be empty")
    address: str = Field(..., min_length=1, description="Address is required")
    city: str = Field("", description="City name")
    state: str = Field("", description="State name")
    postal_code: str = Field("", description="Postal code")
    phone: str = Field(..., min_length=1, description="Phone number is required")
    email: EmailStr = Field(..., description="Valid email address")
    latitude: float = Field(..., ge=-90.0, le=90.0, description="Latitude between -90 and 90")
    longitude: float = Field(..., ge=-180.0, le=180.0, description="Longitude between -180 and 180")
    emergency_available: bool = Field(True, description="Whether emergency services are available")

    @field_validator("name", "address", "phone")
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

    @field_validator("name", "address", "phone")
    @classmethod
    def not_empty_optional(cls, v: Optional[str]) -> Optional[str]:
        if v is not None and (not v or not v.strip()):
            raise ValueError("Field cannot be empty or blank")
        return v.strip() if v else v


class HospitalVerify(BaseModel):
    """Legacy schema — kept for backward compatibility."""
    verification_status: VerificationStatus


class HospitalApprove(BaseModel):
    """System Admin: approve a hospital."""
    pass  # No body required — action is determined by the endpoint


class HospitalReject(BaseModel):
    """System Admin: reject a hospital with an optional reason."""
    rejection_reason: Optional[str] = Field(None, description="Optional reason for rejection")


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
    rejection_reason: Optional[str] = None
    admin_id: Optional[int] = None
    created_by: Optional[int] = None
    approved_by: Optional[int] = None
    approved_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


# ──────────────────────────────────────────────────────────────
# Ward schemas
# ──────────────────────────────────────────────────────────────

class WardCreate(BaseModel):
    name: str = Field(..., min_length=1)
    ward_type: str = Field(..., min_length=1, description="e.g. ICU, GENERAL, EMERGENCY")
    floor: Optional[int] = Field(None, ge=0)
    capacity: Optional[int] = Field(None, ge=1)


class WardUpdate(BaseModel):
    name: Optional[str] = None
    ward_type: Optional[str] = None
    floor: Optional[int] = Field(None, ge=0)
    capacity: Optional[int] = Field(None, ge=1)
    ward_status: Optional[WardStatus] = None


class WardResponse(BaseModel):
    id: int
    hospital_id: int
    name: str
    ward_type: str
    floor: Optional[int] = None
    capacity: Optional[int] = None
    ward_status: WardStatus
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True


# ──────────────────────────────────────────────────────────────
# Bed schemas
# ──────────────────────────────────────────────────────────────

class BedCreate(BaseModel):
    bed_number: str = Field(..., min_length=1)
    bed_type: BedType = Field(BedType.GENERAL, description="Bed type per PRD §8")
    status: BedStatus = Field(BedStatus.AVAILABLE)
    patient_reference: Optional[str] = None


class BedUpdate(BaseModel):
    bed_number: Optional[str] = None
    bed_type: Optional[BedType] = None
    status: Optional[BedStatus] = None
    patient_reference: Optional[str] = None


class BedStatusUpdate(BaseModel):
    """Simple status-only update for Hospital Staff use."""
    status: BedStatus
    notes: Optional[str] = None


class BedResponse(BaseModel):
    id: int
    ward_id: int
    bed_number: str
    bed_type: BedType
    status: BedStatus
    patient_reference: Optional[str] = None
    created_at: datetime
    updated_at: datetime

    class Config:
        from_attributes = True
