import enum
from sqlalchemy import Column, Integer, String, Text, Float, DateTime, Enum, ForeignKey, Boolean
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database.session import Base

class VerificationStatus(str, enum.Enum):
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
    verification_status = Column(Enum(VerificationStatus), nullable=False, default=VerificationStatus.PENDING)
    status = Column(Enum(HospitalStatus), nullable=False, default=HospitalStatus.INACTIVE)
    admin_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # Relationships
    admin = relationship("User", back_populates="hospitals_managed", foreign_keys=[admin_id])
    staff = relationship("HospitalStaff", back_populates="hospital", cascade="all, delete-orphan")
    wards = relationship("Ward", back_populates="hospital", cascade="all, delete-orphan")
    resources = relationship("Resource", back_populates="hospital", cascade="all, delete-orphan")
    ambulances = relationship("Ambulance", back_populates="hospital", cascade="all, delete-orphan")
    emergency_requests = relationship("EmergencyRequest", back_populates="hospital")

class Ward(Base):
    __tablename__ = "wards"

    id = Column(Integer, primary_key=True, autoincrement=True)
    hospital_id = Column(Integer, ForeignKey("hospitals.id", ondelete="CASCADE"), nullable=False, index=True)
    name = Column(String(100), nullable=False)
    ward_type = Column(String(50), nullable=False)  # e.g., ICU, GENERAL, PEDIATRIC
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # Relationships
    hospital = relationship("Hospital", back_populates="wards")
    beds = relationship("Bed", back_populates="ward", cascade="all, delete-orphan")

class Bed(Base):
    __tablename__ = "beds"

    id = Column(Integer, primary_key=True, autoincrement=True)
    ward_id = Column(Integer, ForeignKey("wards.id", ondelete="CASCADE"), nullable=False, index=True)
    bed_number = Column(String(50), nullable=False)
    status = Column(Enum(BedStatus), nullable=False, default=BedStatus.AVAILABLE, index=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # Relationships
    ward = relationship("Ward", back_populates="beds")
    status_history = relationship("BedStatusHistory", back_populates="bed", cascade="all, delete-orphan")

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

class Ambulance(Base):
    __tablename__ = "ambulances"

    id = Column(Integer, primary_key=True, autoincrement=True)
    hospital_id = Column(Integer, ForeignKey("hospitals.id", ondelete="CASCADE"), nullable=False, index=True)
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
