import enum
from sqlalchemy import Column, Integer, String, Text, Float, DateTime, Enum, ForeignKey, Boolean
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database.session import Base


# ──────────────────────────────────────────────
# Enums
# ──────────────────────────────────────────────

class VerificationStatus(str, enum.Enum):
    """Maps to the PRD single-status model via router logic:
    PENDING   → hospital created, awaiting admin review
    VERIFIED  → admin approved   (visible to patients as "APPROVED")
    REJECTED  → admin rejected   (not visible to patients)
    SUSPENDED → admin deactivated after approval
    """
    PENDING = "PENDING"
    VERIFIED = "VERIFIED"
    REJECTED = "REJECTED"
    SUSPENDED = "SUSPENDED"


class HospitalStatus(str, enum.Enum):
    ACTIVE = "ACTIVE"
    INACTIVE = "INACTIVE"


class BedStatus(str, enum.Enum):
    AVAILABLE = "AVAILABLE"
    OCCUPIED = "OCCUPIED"
    MAINTENANCE = "MAINTENANCE"
    RESERVED = "RESERVED"


class BedType(str, enum.Enum):
    """Bed types per architecture.md §13."""
    GENERAL = "GENERAL"
    ICU = "ICU"
    EMERGENCY = "EMERGENCY"
    PRIVATE = "PRIVATE"
    SEMI_PRIVATE = "SEMI_PRIVATE"


class WardStatus(str, enum.Enum):
    ACTIVE = "ACTIVE"
    INACTIVE = "INACTIVE"


# ──────────────────────────────────────────────
# Hospital
# ──────────────────────────────────────────────

class Hospital(Base):
    __tablename__ = "hospitals"

    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(255), nullable=False, index=True)
    address = Column(Text, nullable=False)
    city = Column(String(100), nullable=False, default="")
    state = Column(String(100), nullable=False, default="")
    postal_code = Column(String(20), nullable=False, default="")
    phone = Column(String(100), nullable=False)
    email = Column(String(100), nullable=False)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    emergency_available = Column(Boolean, nullable=False, default=True)

    # Status fields
    verification_status = Column(
        Enum(VerificationStatus), nullable=False, default=VerificationStatus.PENDING
    )
    status = Column(Enum(HospitalStatus), nullable=False, default=HospitalStatus.INACTIVE)

    # Audit / ownership fields (architecture.md §10)
    rejection_reason = Column(Text, nullable=True)
    created_by = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    admin_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    approved_by = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    approved_at = Column(DateTime(timezone=True), nullable=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # Relationships
    admin = relationship("User", back_populates="hospitals_managed", foreign_keys=[admin_id])
    creator = relationship("User", foreign_keys=[created_by])
    approver = relationship("User", foreign_keys=[approved_by])
    staff = relationship("HospitalStaff", back_populates="hospital", cascade="all, delete-orphan")
    wards = relationship("Ward", back_populates="hospital", cascade="all, delete-orphan")
    resources = relationship("Resource", back_populates="hospital", cascade="all, delete-orphan")
    ambulances = relationship("Ambulance", back_populates="hospital", cascade="all, delete-orphan")
    emergency_requests = relationship("EmergencyRequest", back_populates="hospital")


# ──────────────────────────────────────────────
# Ward
# ──────────────────────────────────────────────

class Ward(Base):
    __tablename__ = "wards"

    id = Column(Integer, primary_key=True, autoincrement=True)
    hospital_id = Column(
        Integer, ForeignKey("hospitals.id", ondelete="CASCADE"), nullable=False, index=True
    )
    name = Column(String(100), nullable=False)
    ward_type = Column(String(50), nullable=False)  # e.g., ICU, GENERAL, PEDIATRIC

    # architecture.md §12 additional fields
    floor = Column(Integer, nullable=True)
    capacity = Column(Integer, nullable=True)
    ward_status = Column(Enum(WardStatus), nullable=False, default=WardStatus.ACTIVE)

    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # Relationships
    hospital = relationship("Hospital", back_populates="wards")
    beds = relationship("Bed", back_populates="ward", cascade="all, delete-orphan")


# ──────────────────────────────────────────────
# Bed
# ──────────────────────────────────────────────

class Bed(Base):
    __tablename__ = "beds"

    id = Column(Integer, primary_key=True, autoincrement=True)
    ward_id = Column(Integer, ForeignKey("wards.id", ondelete="CASCADE"), nullable=False, index=True)
    bed_number = Column(String(50), nullable=False)

    # architecture.md §13 — bed type
    bed_type = Column(Enum(BedType), nullable=False, default=BedType.GENERAL)
    patient_reference = Column(String(150), nullable=True)  # optional reference to occupying patient

    status = Column(Enum(BedStatus), nullable=False, default=BedStatus.AVAILABLE, index=True)

    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # Relationships
    ward = relationship("Ward", back_populates="beds")
    status_history = relationship("BedStatusHistory", back_populates="bed", cascade="all, delete-orphan")


# ──────────────────────────────────────────────
# Bed Status History
# ──────────────────────────────────────────────

class BedStatusHistory(Base):
    __tablename__ = "bed_status_history"

    id = Column(Integer, primary_key=True, autoincrement=True)
    bed_id = Column(Integer, ForeignKey("beds.id", ondelete="CASCADE"), nullable=False, index=True)
    from_status = Column(Enum(BedStatus), nullable=False)
    to_status = Column(Enum(BedStatus), nullable=False)
    changed_by_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    changed_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    notes = Column(Text, nullable=True)

    # Relationships
    bed = relationship("Bed", back_populates="status_history")
    changed_by = relationship("User", back_populates="bed_changes")


# ──────────────────────────────────────────────
# Ambulance
# ──────────────────────────────────────────────

class Ambulance(Base):
    __tablename__ = "ambulances"

    id = Column(Integer, primary_key=True, autoincrement=True)
    hospital_id = Column(
        Integer, ForeignKey("hospitals.id", ondelete="CASCADE"), nullable=False, index=True
    )
    plate_number = Column(String(30), unique=True, nullable=False, index=True)
    driver_name = Column(String(100), nullable=False)
    driver_phone = Column(String(100), nullable=False)
    is_available = Column(Boolean, nullable=False, default=True, index=True)
    latitude = Column(Float, nullable=True)
    longitude = Column(Float, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # Relationships
    hospital = relationship("Hospital", back_populates="ambulances")
    emergency_requests = relationship("EmergencyRequest", back_populates="assigned_ambulance")
