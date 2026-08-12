import enum
from sqlalchemy import Column, Integer, String, Text, Float, DateTime, Enum, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database.session import Base

class EmergencyRequestStatus(str, enum.Enum):
    PENDING = "PENDING"
    ACCEPTED = "ACCEPTED"
    REJECTED = "REJECTED"
    CANCELLED = "CANCELLED"
    COMPLETED = "COMPLETED"

class EmergencyRequest(Base):
    __tablename__ = "emergency_requests"

    id = Column(Integer, primary_key=True, autoincrement=True)
    patient_id = Column(Integer, ForeignKey("users.id", ondelete="CASCADE"), nullable=False, index=True)
    hospital_id = Column(Integer, ForeignKey("hospitals.id", ondelete="SET NULL"), nullable=True, index=True)
    status = Column(Enum(EmergencyRequestStatus), nullable=False, default=EmergencyRequestStatus.PENDING, index=True)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    severity = Column(String(30), nullable=False)  # e.g., LOW, MEDIUM, CRITICAL
    incident_description = Column(Text, nullable=True)
    assigned_ambulance_id = Column(Integer, ForeignKey("ambulances.id", ondelete="SET NULL"), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # Relationships
    patient = relationship("User", back_populates="emergency_requests")
    hospital = relationship("Hospital", back_populates="emergency_requests")
    assigned_ambulance = relationship("Ambulance", back_populates="emergency_requests")
