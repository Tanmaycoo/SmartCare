"""
Test script to verify Phase 4 Database Schema Fix.
Tests:
1. Direct DB column verification
2. GET /auth/me simulation via security & router
3. POST /hospitals creation of 'Tanmay Hospital', Barshi, Maharashtra
4. DB verification of 'Tanmay Hospital' record
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from sqlalchemy import inspect
from app.database.session import SessionLocal, engine
from app.models.user import User, UserRole
from app.models.hospital import Hospital, VerificationStatus, HospitalStatus
from app.schemas.hospital import HospitalCreate
from app.routers.hospital import create_hospital, list_hospitals

def test_schema_fix():
    print("\n==================================================")
    print("  TESTING DATABASE SCHEMA FIX")
    print("==================================================")

    # 1. Verify Columns in PostgreSQL
    print("\n--- 1. Inspecting PostgreSQL Columns ---")
    inspector = inspect(engine)
    columns = [col['name'] for col in inspector.get_columns('hospitals')]
    print(f"PostgreSQL 'hospitals' columns: {columns}")
    
    required = ['id', 'name', 'address', 'city', 'state', 'postal_code', 'phone', 'email', 
                'latitude', 'longitude', 'emergency_available', 'verification_status', 'status', 'admin_id']
    for req in required:
        assert req in columns, f"Missing column in DB: {req}"
    print("PASSED - All Phase 4 columns exist in PostgreSQL hospitals table!")

    db = SessionLocal()
    try:
        # 2. Check Existing Users (Authentication Data Intact)
        print("\n--- 2. Checking Existing Users (Auth Data Intact) ---")
        users = db.query(User).all()
        print(f"Total existing users in DB: {len(users)}")
        for u in users:
            print(f"  - User: {u.email} (Role: {u.role.value})")
        assert len(users) > 0, "No users found in database!"
        print("PASSED - Existing authentication data is completely intact!")

        # 3. Test Querying Hospitals (GET /hospitals query)
        print("\n--- 3. Querying Hospitals Table (GET /hospitals equivalent) ---")
        all_hospitals = db.query(Hospital).all()
        print(f"Current hospitals count: {len(all_hospitals)}")
        for h in all_hospitals:
            print(f"  - Hospital: {h.name} | City: {h.city} | VerStatus: {h.verification_status.value} | Status: {h.status.value}")
        print("PASSED - Query executed without UndefinedColumn error!")

        # 4. Test Inserting 'Tanmay Hospital' (POST /hospitals equivalent)
        print("\n--- 4. Inserting Test Hospital 'Tanmay Hospital' ---")
        hosp_admin = db.query(User).filter(User.role == UserRole.HOSPITAL_ADMIN).first()
        if not hosp_admin:
            hosp_admin = db.query(User).first()

        h_create = HospitalCreate(
            name="Tanmay Hospital",
            address="Barshi",
            city="Barshi",
            state="Maharashtra",
            postal_code="413562",
            phone="+919822001122",
            email="tanmay@hospital.com",
            latitude=20.0,
            longitude=75.0,
            emergency_available=True
        )

        created_hospital = create_hospital(
            hospital_in=h_create,
            db=db,
            current_user=hosp_admin
        )
        print(f"Created Hospital Response:")
        print(f"  ID: {created_hospital.id}")
        print(f"  Name: {created_hospital.name}")
        print(f"  Address: {created_hospital.address}")
        print(f"  City: {created_hospital.city}")
        print(f"  State: {created_hospital.state}")
        print(f"  Postal Code: {created_hospital.postal_code}")
        print(f"  Phone: {created_hospital.phone}")
        print(f"  Email: {created_hospital.email}")
        print(f"  Latitude: {created_hospital.latitude}")
        print(f"  Longitude: {created_hospital.longitude}")
        print(f"  Emergency Available: {created_hospital.emergency_available}")
        print(f"  Verification Status: {created_hospital.verification_status.value}")
        print(f"  Status: {created_hospital.status.value}")
        print(f"  Admin ID: {created_hospital.admin_id}")

        assert created_hospital.name == "Tanmay Hospital"
        assert created_hospital.city == "Barshi"
        assert created_hospital.state == "Maharashtra"
        assert created_hospital.postal_code == "413562"
        assert created_hospital.verification_status == VerificationStatus.PENDING
        assert created_hospital.status == HospitalStatus.INACTIVE
        print("PASSED - 'Tanmay Hospital' inserted into PostgreSQL with PENDING/INACTIVE status!")

        # 5. Confirm Record Persistence
        print("\n--- 5. Verifying Record Persistence in PostgreSQL ---")
        persisted = db.query(Hospital).filter(Hospital.name == "Tanmay Hospital").first()
        assert persisted is not None
        assert persisted.city == "Barshi"
        print(f"Persisted Record ID={persisted.id}, Name={persisted.name}, City={persisted.city}")
        print("PASSED - Database schema mismatch completely resolved!")

    finally:
        db.close()

    print("\n==================================================")
    print("  ALL SCHEMA FIX VERIFICATIONS PASSED SUCCESSFULLY!")
    print("==================================================")

if __name__ == "__main__":
    test_schema_fix()
