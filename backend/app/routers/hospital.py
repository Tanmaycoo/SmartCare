from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from app.database.session import get_db
from app.models.user import User, UserRole, HospitalStaff
from app.models.hospital import Hospital, VerificationStatus, HospitalStatus
from app.schemas.hospital import HospitalCreate, HospitalUpdate, HospitalVerify, HospitalResponse
from app.routers.deps import (
    get_current_user,
    allow_patient,
    allow_hospital_staff,
    allow_hospital_admin,
    allow_system_admin,
)

router = APIRouter(prefix="/hospitals", tags=["Hospitals"])

@router.post("", response_model=HospitalResponse, status_code=status.HTTP_201_CREATED)
@router.post("/", response_model=HospitalResponse, status_code=status.HTTP_201_CREATED, include_in_schema=False)
def create_hospital(
    hospital_in: HospitalCreate,
    db: Session = Depends(get_db),
    current_user: User = Depends(allow_hospital_admin)
):
    """
    Register a new hospital.
    Only HOSPITAL_ADMIN or SYSTEM_ADMIN can create hospitals.
    Initial status: PENDING verification, INACTIVE status.
    """
    hospital = Hospital(
        name=hospital_in.name,
        address=hospital_in.address,
        city=hospital_in.city,
        state=hospital_in.state,
        postal_code=hospital_in.postal_code,
        phone=hospital_in.phone,
        email=hospital_in.email,
        latitude=hospital_in.latitude,
        longitude=hospital_in.longitude,
        emergency_available=hospital_in.emergency_available,
        verification_status=VerificationStatus.PENDING,
        status=HospitalStatus.INACTIVE,
        admin_id=current_user.id if current_user.role == UserRole.HOSPITAL_ADMIN else None
    )
    db.add(hospital)
    db.commit()
    db.refresh(hospital)
    return hospital

@router.get("", response_model=List[HospitalResponse])
@router.get("/", response_model=List[HospitalResponse], include_in_schema=False)
def list_hospitals(
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user),
    verification_status: Optional[VerificationStatus] = Query(None),
    status_param: Optional[HospitalStatus] = Query(None, alias="status")
):
    """
    Return hospitals authorized for the current user.
    - PATIENT: Only VERIFIED + ACTIVE hospitals.
    - HOSPITAL_STAFF: Assigned hospital or active hospitals.
    - HOSPITAL_ADMIN: Own hospital(s) or active hospitals.
    - SYSTEM_ADMIN: All hospitals, optional filtering by verification_status and status.
    """
    query = db.query(Hospital)

    if current_user.role == UserRole.SYSTEM_ADMIN:
        if verification_status:
            query = query.filter(Hospital.verification_status == verification_status)
        if status_param:
            query = query.filter(Hospital.status == status_param)
        return query.all()

    if current_user.role == UserRole.PATIENT:
        return query.filter(
            Hospital.verification_status == VerificationStatus.VERIFIED,
            Hospital.status == HospitalStatus.ACTIVE
        ).all()

    if current_user.role == UserRole.HOSPITAL_ADMIN:
        # Return admin's own hospitals plus active verified ones
        admin_hospitals = query.filter(
            (Hospital.admin_id == current_user.id) |
            ((Hospital.verification_status == VerificationStatus.VERIFIED) & (Hospital.status == HospitalStatus.ACTIVE))
        ).all()
        return admin_hospitals

    if current_user.role == UserRole.HOSPITAL_STAFF:
        staff_entry = db.query(HospitalStaff).filter(HospitalStaff.user_id == current_user.id).first()
        staff_hospital_id = staff_entry.hospital_id if staff_entry else None
        staff_hospitals = query.filter(
            (Hospital.id == staff_hospital_id) |
            ((Hospital.verification_status == VerificationStatus.VERIFIED) & (Hospital.status == HospitalStatus.ACTIVE))
        ).all()
        return staff_hospitals

    # Default fallback: active verified hospitals
    return query.filter(
        Hospital.verification_status == VerificationStatus.VERIFIED,
        Hospital.status == HospitalStatus.ACTIVE
    ).all()

@router.get("/{hospital_id}", response_model=HospitalResponse)
def get_hospital(
    hospital_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(get_current_user)
):
    """
    Get detailed information for a specific hospital.
    """
    hospital = db.query(Hospital).filter(Hospital.id == hospital_id).first()
    if not hospital:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Hospital not found"
        )

    # Patients can only view VERIFIED + ACTIVE hospitals
    if current_user.role == UserRole.PATIENT:
        if hospital.verification_status != VerificationStatus.VERIFIED or hospital.status != HospitalStatus.ACTIVE:
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Hospital is not active or verified"
            )

    return hospital

@router.put("/{hospital_id}", response_model=HospitalResponse)
def update_hospital(
    hospital_id: int,
    hospital_in: HospitalUpdate,
    db: Session = Depends(get_db),
    current_user: User = Depends(allow_hospital_admin)
):
    """
    Update hospital details.
    HOSPITAL_ADMIN can only update their own hospital.
    SYSTEM_ADMIN can update any hospital.
    """
    hospital = db.query(Hospital).filter(Hospital.id == hospital_id).first()
    if not hospital:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Hospital not found"
        )

    # Check permission: HOSPITAL_ADMIN must own this hospital
    if current_user.role == UserRole.HOSPITAL_ADMIN:
        if hospital.admin_id != current_user.id:
            # Check if user is staff for this hospital
            staff = db.query(HospitalStaff).filter(
                HospitalStaff.user_id == current_user.id,
                HospitalStaff.hospital_id == hospital_id
            ).first()
            if not staff and hospital.admin_id is not None:
                raise HTTPException(
                    status_code=status.HTTP_403_FORBIDDEN,
                    detail="You do not have permission to update another hospital"
                )

    update_data = hospital_in.model_dump(exclude_unset=True)
    for field, value in update_data.items():
        setattr(hospital, field, value)

    db.commit()
    db.refresh(hospital)
    return hospital

@router.patch("/{hospital_id}/verify", response_model=HospitalResponse)
def verify_hospital(
    hospital_id: int,
    verify_in: HospitalVerify,
    db: Session = Depends(get_db),
    current_user: User = Depends(allow_system_admin)
):
    """
    SYSTEM_ADMIN endpoint to approve (VERIFIED) or reject (REJECTED) a hospital.
    Approving sets verification_status = VERIFIED and status = ACTIVE.
    Rejecting sets verification_status = REJECTED and status = INACTIVE.
    """
    hospital = db.query(Hospital).filter(Hospital.id == hospital_id).first()
    if not hospital:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Hospital not found"
        )

    if verify_in.verification_status not in [VerificationStatus.VERIFIED, VerificationStatus.REJECTED]:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Verification status must be VERIFIED or REJECTED"
        )

    hospital.verification_status = verify_in.verification_status
    if verify_in.verification_status == VerificationStatus.VERIFIED:
        hospital.status = HospitalStatus.ACTIVE
    else:
        hospital.status = HospitalStatus.INACTIVE

    db.commit()
    db.refresh(hospital)
    return hospital

@router.patch("/{hospital_id}/activate", response_model=HospitalResponse)
def activate_hospital(
    hospital_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(allow_system_admin)
):
    """
    SYSTEM_ADMIN endpoint to activate a hospital.
    Sets status = ACTIVE. If verification_status is PENDING, also updates it to VERIFIED.
    """
    hospital = db.query(Hospital).filter(Hospital.id == hospital_id).first()
    if not hospital:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Hospital not found"
        )

    hospital.status = HospitalStatus.ACTIVE
    if hospital.verification_status == VerificationStatus.PENDING:
        hospital.verification_status = VerificationStatus.VERIFIED

    db.commit()
    db.refresh(hospital)
    return hospital

@router.patch("/{hospital_id}/suspend", response_model=HospitalResponse)
def suspend_hospital(
    hospital_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(allow_system_admin)
):
    """
    SYSTEM_ADMIN endpoint to suspend a hospital.
    Sets verification_status = SUSPENDED and status = INACTIVE.
    """
    hospital = db.query(Hospital).filter(Hospital.id == hospital_id).first()
    if not hospital:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Hospital not found"
        )

    hospital.verification_status = VerificationStatus.SUSPENDED
    hospital.status = HospitalStatus.INACTIVE

    db.commit()
    db.refresh(hospital)
    return hospital

@router.delete("/{hospital_id}", status_code=status.HTTP_200_OK)
def delete_hospital(
    hospital_id: int,
    db: Session = Depends(get_db),
    current_user: User = Depends(allow_system_admin)
):
    """
    SYSTEM_ADMIN endpoint to delete/deactivate a hospital.
    Soft-deactivates the hospital by setting status = INACTIVE and verification_status = REJECTED.
    """
    hospital = db.query(Hospital).filter(Hospital.id == hospital_id).first()
    if not hospital:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail="Hospital not found"
        )

    hospital.status = HospitalStatus.INACTIVE
    hospital.verification_status = VerificationStatus.REJECTED
    db.commit()
    return {"message": f"Hospital {hospital_id} has been deactivated", "id": hospital_id}
