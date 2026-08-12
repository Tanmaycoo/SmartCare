import enum
from sqlalchemy import Column, Integer, String, DateTime, Enum, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database.session import Base

class UserRole(str, enum.Enum):
    PATIENT = "patient"
    HOSPITAL_STAFF = "hospital_staff"
    HOSPITAL_ADMIN = "hospital_admin"
    SYSTEM_ADMIN = "system_admin"

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, autoincrement=True)
    email = Column(String(255), unique=True, nullable=False, index=True)
    password_hash = Column(String(255), nullable=False)
    full_name = Column(String(150), nullable=False)
    phone = Column(String(20), nullable=True)
    role = Column(Enum(UserRole), nullable=False, default=UserRole.PATIENT)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # Relationships
    staff_profile = relationship("HospitalStaff", back_populates="user", uselist=False)
    hospitals_managed = relationship("Hospital", back_populates="admin")
    emergency_requests = relationship("EmergencyRequest", back_populates="patient")
    notifications = relationship("Notification", back_populates="user")
    bed_changes = relationship("BedStatusHistory", back_populates="changed_by")
    resource_changes = relationship("ResourceStatusHistory", back_populates="changed_by")

class HospitalStaff(Base):
    __tablename__ = "hospital_staff"

    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), unique=True, nullable=False, index=True)
    hospital_id = Column(Integer, ForeignKey("hospitals.id", ondelete="CASCADE"), nullable=False, index=True)
    designation = Column(String(100), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # Relationships
    user = relationship("User", back_populates="staff_profile")
    hospital = relationship("Hospital", back_populates="staff")
