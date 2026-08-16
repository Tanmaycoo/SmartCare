"""
beds.py — Ward and Bed management endpoints (Phase 5).

Endpoints per architecture.md §18:
  POST   /hospitals/{hospital_id}/wards              → add ward
  GET    /hospitals/{hospital_id}/wards              → list wards
  PUT    /hospitals/{hospital_id}/wards/{ward_id}    → update ward
  POST   /hospitals/{hospital_id}/beds               → add bed to hospital (auto-ward optional)
  GET    /hospitals/{hospital_id}/beds               → list beds (with optional ward filter)
  POST   /wards/{ward_id}/beds                       → add bed to specific ward
  GET    /wards/{ward_id}/beds                       → list beds in ward
  PUT    /beds/{bed_id}                              → update bed
  PATCH  /beds/{bed_id}/status                       → update bed status only
  DELETE /beds/{bed_id}                              → delete/disable bed

Authorization per rules.md §7-8:
  Hospital Staff / Hospital Admin: manage beds of their own hospital only.
  System Admin: can manage any.
"""

from typing import List, Optional
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session

from app.database.session import get_db
from app.models.user import User, UserRole, HospitalStaff
from app.models.hospital import Hospital, Ward, Bed, BedStatus, BedStatusHistory, VerificationStatus, HospitalStatus
from app.schemas.hospital import (
    WardCreate, WardUpdate, WardResponse,
    BedCreate, BedUpdate, BedStatusUpdate, BedResponse,
)
from app.routers.deps import get_current_user, allow_hospital_staff, allow_system_admin

router = APIRouter(tags=["Beds & Wards"])


# ──────────────────────────────────────────────
# Helpers
# ──────────────────────────────────────────────

def _get_hospital_or_404(hospital_id: int, db: Session) -> Hospital:
    h = db.query(Hospital).filter(Hospital.id == hospital_id).first()
    if not h:
        raise HTTPException(status_code=404, detail="Hospital not found")
    return h


def _get_ward_or_404(ward_id: int, db: Session) -> Ward:
    w = db.query(Ward).filter(Ward.id == ward_id).first()
    if not w:
        raise HTTPException(status_code=404, detail="Ward not found")
    return w


def _get_bed_or_404(bed_id: int, db: Session) -> Bed:
    b = db.query(Bed).filter(Bed.id == bed_id).first()
    if not b:
        raise HTTPException(status_code=404, detail="Bed not found")
    return b


def _verify_hospital_access(hospital: Hospital, current_user: User, db: Session):
    """Verify current user has authority over this hospital (rules.md §6)."""
    if current_user.role == UserRole.SYSTEM_ADMIN:
        return  # full access

    if current_user.role == UserRole.HOSPITAL_ADMIN:
        if hospital.admin_id != current_user.id:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You do not have permission to manage this hospital",
            )
        return

    if current_user.role == UserRole.HOSPITAL_STAFF:
        staff = db.query(HospitalStaff).filter(
            HospitalStaff.user_id == current_user.id,
            HospitalStaff.hospital_id == hospital.id,
        ).first()
        if not staff:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You are not assigned to this hospital",
            )
        return

    raise HTTPException(status_code=status.HTTP_403_FORBIDDEN, detail="Access denied")


# ──────────────────────────────────────────────
# Ward endpoints
# ──────────────────────────────────────────────

@router.post("/hospitals/{hospital_id}/wards", response_model=WardResponse, status_code=201)
def create_ward(
    hospital_id: int,
    ward_in: WardCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(allow_hospital_staff),
):
    """Add a ward to a hospital. Hospital Staff / Admin of that hospital only."""
    hospital = _get_hospital_or_404(hospital_id, db)
    _verify_hospital_access(hospital, current_user, db)

    ward = Ward(
        hospital_id=hospital_id,
        name=ward_in.name,
        ward_type=ward_in.ward_type,
        floor=ward_in.floor,
        capacity=ward_in.capacity,
    )
    db.add(ward)
    db.commit()
    db.refresh(ward)
    return ward


@router.get("/hospitals/{hospital_id}/wards", response_model=List[WardResponse])
def list_wards(
    hospital_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """List all wards for a hospital."""
    hospital = _get_hospital_or_404(hospital_id, db)

    # Patients can only see APPROVED hospitals
    if current_user.role == UserRole.PATIENT:
        if (hospital.verification_status != VerificationStatus.VERIFIED
                or hospital.status != HospitalStatus.ACTIVE):
            raise HTTPException(status_code=403, detail="Hospital is not publicly available")

    return db.query(Ward).filter(Ward.hospital_id == hospital_id).all()


@router.put("/hospitals/{hospital_id}/wards/{ward_id}", response_model=WardResponse)
def update_ward(
    hospital_id: int,
    ward_id: int,
    ward_in: WardUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(allow_hospital_staff),
):
    """Update ward information. Hospital Staff / Admin of that hospital only."""
    hospital = _get_hospital_or_404(hospital_id, db)
    _verify_hospital_access(hospital, current_user, db)
    ward = _get_ward_or_404(ward_id, db)

    if ward.hospital_id != hospital_id:
        raise HTTPException(status_code=404, detail="Ward not found in this hospital")

    for field, value in ward_in.model_dump(exclude_unset=True).items():
        setattr(ward, field, value)

    db.commit()
    db.refresh(ward)
    return ward


# ──────────────────────────────────────────────
# Bed endpoints (ward-scoped)
# ──────────────────────────────────────────────

@router.post("/wards/{ward_id}/beds", response_model=BedResponse, status_code=201)
def create_bed_in_ward(
    ward_id: int,
    bed_in: BedCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(allow_hospital_staff),
):
    """Add a bed to a specific ward. Verifies hospital ownership."""
    ward = _get_ward_or_404(ward_id, db)
    hospital = _get_hospital_or_404(ward.hospital_id, db)
    _verify_hospital_access(hospital, current_user, db)

    bed = Bed(
        ward_id=ward_id,
        bed_number=bed_in.bed_number,
        bed_type=bed_in.bed_type,
        status=bed_in.status,
        patient_reference=bed_in.patient_reference,
    )
    db.add(bed)
    db.commit()
    db.refresh(bed)
    return bed


@router.get("/wards/{ward_id}/beds", response_model=List[BedResponse])
def list_beds_in_ward(
    ward_id: int,
    status_filter: Optional[BedStatus] = Query(None, alias="status"),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """List beds in a ward. Patients can only see beds of APPROVED hospitals."""
    ward = _get_ward_or_404(ward_id, db)
    hospital = _get_hospital_or_404(ward.hospital_id, db)

    if current_user.role == UserRole.PATIENT:
        if (hospital.verification_status != VerificationStatus.VERIFIED
                or hospital.status != HospitalStatus.ACTIVE):
            raise HTTPException(status_code=403, detail="Hospital is not publicly available")

    query = db.query(Bed).filter(Bed.ward_id == ward_id)
    if status_filter:
        query = query.filter(Bed.status == status_filter)

    return query.all()


# ──────────────────────────────────────────────
# Bed endpoints (hospital-scoped convenience)
# ──────────────────────────────────────────────

@router.get("/hospitals/{hospital_id}/beds", response_model=List[BedResponse])
def list_beds_for_hospital(
    hospital_id: int,
    status_filter: Optional[BedStatus] = Query(None, alias="status"),
    ward_id: Optional[int] = Query(None),
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
):
    """
    List all beds for a hospital (across all wards).
    Optionally filter by bed status or ward_id.
    """
    hospital = _get_hospital_or_404(hospital_id, db)

    if current_user.role == UserRole.PATIENT:
        if (hospital.verification_status != VerificationStatus.VERIFIED
                or hospital.status != HospitalStatus.ACTIVE):
            raise HTTPException(status_code=403, detail="Hospital is not publicly available")

    # Join through wards
    query = (
        db.query(Bed)
        .join(Ward, Bed.ward_id == Ward.id)
        .filter(Ward.hospital_id == hospital_id)
    )
    if ward_id:
        query = query.filter(Bed.ward_id == ward_id)
    if status_filter:
        query = query.filter(Bed.status == status_filter)

    return query.all()


# ──────────────────────────────────────────────
# Individual bed management
# ──────────────────────────────────────────────

@router.put("/beds/{bed_id}", response_model=BedResponse)
def update_bed(
    bed_id: int,
    bed_in: BedUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(allow_hospital_staff),
):
    """Update bed details. Verifies hospital ownership (rules.md §8)."""
    bed = _get_bed_or_404(bed_id, db)
    ward = _get_ward_or_404(bed.ward_id, db)
    hospital = _get_hospital_or_404(ward.hospital_id, db)
    _verify_hospital_access(hospital, current_user, db)

    for field, value in bed_in.model_dump(exclude_unset=True).items():
        setattr(bed, field, value)

    db.commit()
    db.refresh(bed)
    return bed


@router.patch("/beds/{bed_id}/status", response_model=BedResponse)
def update_bed_status(
    bed_id: int,
    status_in: BedStatusUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(allow_hospital_staff),
):
    """
    Update bed status only. Records change in bed_status_history.
    Hospital Staff use this to mark beds AVAILABLE / OCCUPIED / MAINTENANCE / RESERVED.
    """
    bed = _get_bed_or_404(bed_id, db)
    ward = _get_ward_or_404(bed.ward_id, db)
    hospital = _get_hospital_or_404(ward.hospital_id, db)
    _verify_hospital_access(hospital, current_user, db)

    old_status = bed.status
    bed.status = status_in.status

    # Record history
    history = BedStatusHistory(
        bed_id=bed_id,
        from_status=old_status,
        to_status=status_in.status,
        changed_by_id=current_user.id,
        notes=status_in.notes,
    )
    db.add(history)
    db.commit()
    db.refresh(bed)
    return bed


@router.delete("/beds/{bed_id}", status_code=200)
def delete_bed(
    bed_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(allow_hospital_staff),
):
    """Delete a bed. Verifies hospital ownership."""
    bed = _get_bed_or_404(bed_id, db)
    ward = _get_ward_or_404(bed.ward_id, db)
    hospital = _get_hospital_or_404(ward.hospital_id, db)
    _verify_hospital_access(hospital, current_user, db)

    db.delete(bed)
    db.commit()
    return {"message": f"Bed {bed_id} deleted", "id": bed_id}
