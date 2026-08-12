from sqlalchemy import Column, Integer, String, DateTime, ForeignKey
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from app.database.session import Base

class Resource(Base):
    __tablename__ = "resources"

    id = Column(Integer, primary_key=True, autoincrement=True)
    hospital_id = Column(Integer, ForeignKey("hospitals.id", ondelete="CASCADE"), nullable=False, index=True)
    name = Column(String(150), nullable=False)
    resource_type = Column(String(50), nullable=False)  # e.g., VENTILATOR, OXYGEN, PPE
    total_quantity = Column(Integer, nullable=False, default=0)
    available_quantity = Column(Integer, nullable=False, default=0)
    created_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)
    updated_at = Column(DateTime(timezone=True), server_default=func.now(), onupdate=func.now(), nullable=False)

    # Relationships
    hospital = relationship("Hospital", back_populates="resources")
    status_history = relationship("ResourceStatusHistory", back_populates="resource", cascade="all, delete-orphan")

class ResourceStatusHistory(Base):
    __tablename__ = "resource_status_history"

    id = Column(Integer, primary_key=True, autoincrement=True)
    resource_id = Column(Integer, ForeignKey("resources.id", ondelete="CASCADE"), nullable=False, index=True)
    old_total = Column(Integer, nullable=False)
    new_total = Column(Integer, nullable=False)
    old_available = Column(Integer, nullable=False)
    new_available = Column(Integer, nullable=False)
    changed_by_id = Column(Integer, ForeignKey("users.id", ondelete="SET NULL"), nullable=True)
    changed_at = Column(DateTime(timezone=True), server_default=func.now(), nullable=False)

    # Relationships
    resource = relationship("Resource", back_populates="status_history")
    changed_by = relationship("User", back_populates="resource_changes")
