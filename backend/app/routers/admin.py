"""
admin.py — System Admin hospital management endpoints.

Endpoints per architecture.md §18:
  GET  /admin/hospitals/pending         → list pending hospitals
  POST /admin/hospitals/{id}/approve    → approve hospital
  POST /admin/hospitals/{id}/reject     → reject hospital with optional reason
  POST /admin/hospitals/{id}/activate   → re-activate a deactivated hospital
  POST /admin/hospitals/{id}/deactivate → deactivate an approved hospital

All endpoints require SYSTEM_ADMIN role.
"""

from datetime import datetime
from typing import List

from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session

from app.database.session import get_db
from app.models.user import User
from app.models.hospital import Hospital, VerificationStatus, HospitalStatus
from app.schemas.hospital import HospitalResponse, HospitalReject
from app.routers.deps import allow_system_admin

router = APIRouter(prefix="/admin/hospitals", tags=["Admin — Hospital Management"])


def _get_hospital_or_404(hospital_id: int, db: Session) -> Hospital:
    hospital = db.query(Hospital).filter(Hospital.id == hospital_id).first()
    if not hospital:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Hospital not found",
        )
    return hospital


@router.get("/pending", response_model=List[HospitalResponse])
def list_pending_hospitals(
    db: Session = Depends(get_db),
    current_user: User = Depends(allow_system_admin),
):
    """
    Return all hospitals with PENDING verification status.
    Used by System Admin to review new hospital registrations.
    """
    return (
        db.query(Hospital)
        .filter(Hospital.verification_status == VerificationStatus.PENDING)
        .order_by(Hospital.created_at.asc())
        .all()
    )


@router.get("", response_model=List[HospitalResponse])
def list_all_hospitals_admin(
    db: Session = Depends(get_db),
    current_user: User = Depends(allow_system_admin),
):
    """Return ALL hospitals regardless of status. System Admin only."""
    return db.query(Hospital).order_by(Hospital.created_at.desc()).all()


@router.post("/{hospital_id}/approve", response_model=HospitalResponse)
def approve_hospital(
    hospital_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(allow_system_admin),
):
    """
    Approve a hospital registration.
    Sets verification_status = VERIFIED, status = ACTIVE.
    Records approver and approval timestamp.

    Workflow (rules.md §23):
      PENDING → APPROVED (VERIFIED + ACTIVE)
    """
    hospital = _get_hospital_or_404(hospital_id, db)

    if hospital.verification_status == VerificationStatus.VERIFIED:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Hospital is already approved",
        )

    hospital.verification_status = VerificationStatus.VERIFIED
    hospital.status = HospitalStatus.ACTIVE
    hospital.approved_by = current_user.id
    hospital.approved_at = datetime.utcnow()
    hospital.rejection_reason = None  # clear any previous rejection reason

    db.commit()
    db.refresh(hospital)
    return hospital


@router.post("/{hospital_id}/reject", response_model=HospitalResponse)
def reject_hospital(
    hospital_id: int,
    reject_data: HospitalReject,
    db: Session = Depends(get_db),
    current_user: User = Depends(allow_system_admin),
):
    """
    Reject a hospital registration.
    Sets verification_status = REJECTED, status = INACTIVE.
    Optionally stores a rejection_reason.

    Workflow (rules.md §4):
      PENDING → REJECTED
    """
    hospital = _get_hospital_or_404(hospital_id, db)

    if hospital.verification_status == VerificationStatus.REJECTED:
        raise HTTPException(
            status_code=status.HTTP_409_CONFLICT,
            detail="Hospital is already rejected",
        )

    hospital.verification_status = VerificationStatus.REJECTED
    hospital.status = HospitalStatus.INACTIVE
    hospital.rejection_reason = reject_data.rejection_reason

    db.commit()
    db.refresh(hospital)
    return hospital


@router.post("/{hospital_id}/activate", response_model=HospitalResponse)
def activate_hospital(
    hospital_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(allow_system_admin),
):
    """
    Re-activate a previously approved hospital.
    Sets status = ACTIVE, verification_status = VERIFIED.

    Workflow (rules.md §20):
      INACTIVE → APPROVED (VERIFIED + ACTIVE)
    """
    hospital = _get_hospital_or_404(hospital_id, db)

    hospital.verification_status = VerificationStatus.VERIFIED
    hospital.status = HospitalStatus.ACTIVE
    hospital.approved_by = current_user.id
    hospital.approved_at = datetime.utcnow()

    db.commit()
    db.refresh(hospital)
    return hospital


@router.post("/{hospital_id}/deactivate", response_model=HospitalResponse)
def deactivate_hospital(
    hospital_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(allow_system_admin),
):
    """
    Deactivate an approved hospital (temporarily suspend from patient view).
    Sets status = INACTIVE (keeps verification_status = VERIFIED for reactivation).

    Workflow (rules.md §20):
      APPROVED → INACTIVE
    """
    hospital = _get_hospital_or_404(hospital_id, db)

    hospital.status = HospitalStatus.INACTIVE

    db.commit()
    db.refresh(hospital)
    return hospital
