import os
import sys
# Add current directory to path if run from root
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy.orm import Session
from app.database.session import Base, engine, SessionLocal
from app.models import (
    User, UserRole, Hospital, VerificationStatus, HospitalStatus, HospitalStaff,
    Ward, Bed, BedStatus, Resource, Ambulance
)

# Import all models to ensure they are registered on the Base metadata
import app.models

def seed_data(db: Session):
    # Check if we already have users (to prevent duplicate seeding)
    if db.query(User).first() is not None:
        print("Database already contains data. Seeding skipped.")
        return

    print("Seeding initial development data...")

    # Helper password hashing
    try:
        from passlib.context import CryptContext
        pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
        hash_pwd = pwd_context.hash
    except Exception:
        print("Warning: passlib bcrypt not available, using plain password hashes")
        def hash_pwd(p): return f"mock_hash_{p}"

    # 1. Create Users
    admin_user = User(
        email="admin@smartcare.com",
        password_hash=hash_pwd("admin123"),
        full_name="System Administrator",
        phone="+919876543210",
        role=UserRole.SYSTEM_ADMIN
    )
    hosp_admin_user = User(
        email="hospadmin@citygeneral.com",
        password_hash=hash_pwd("admin123"),
        full_name="Dr. Robert Admin",
        phone="+919876543214",
        role=UserRole.HOSPITAL_ADMIN
    )
    staff_user1 = User(
        email="staff1@citygeneral.com",
        password_hash=hash_pwd("staff123"),
        full_name="Dr. Jane Smith",
        phone="+919876543211",
        role=UserRole.HOSPITAL_STAFF
    )
    staff_user2 = User(
        email="staff2@metrocare.com",
        password_hash=hash_pwd("staff123"),
        full_name="Nurse John Doe",
        phone="+919876543212",
        role=UserRole.HOSPITAL_STAFF
    )
    patient_user = User(
        email="patient@gmail.com",
        password_hash=hash_pwd("patient123"),
        full_name="Amit Kumar",
        phone="+919876543213",
        role=UserRole.PATIENT
    )

    db.add_all([admin_user, hosp_admin_user, staff_user1, staff_user2, patient_user])
    db.commit()  # Commit to get IDs

    # 2. Create Hospitals
    hospital1 = Hospital(
        name="City General Hospital",
        address="123 Health Ave, Sector 4",
        city="New Delhi",
        state="Delhi",
        postal_code="110001",
        latitude=28.6139,
        longitude=77.2090,
        phone="011-23456789",
        email="info@citygeneral.com",
        emergency_available=True,
        verification_status=VerificationStatus.VERIFIED,
        status=HospitalStatus.ACTIVE,
        admin_id=hosp_admin_user.id
    )
    hospital2 = Hospital(
        name="Metro Emergency Care",
        address="456 Rescue Rd, Sector 15",
        city="Gurugram",
        state="Haryana",
        postal_code="122001",
        latitude=28.4595,
        longitude=77.0266,
        phone="0124-9876543",
        email="emergency@metrocare.com",
        emergency_available=True,
        verification_status=VerificationStatus.VERIFIED,
        status=HospitalStatus.ACTIVE
    )

    db.add_all([hospital1, hospital2])
    db.commit()

    # 3. Create Staff relationships
    staff1 = HospitalStaff(
        user_id=staff_user1.id,
        hospital_id=hospital1.id,
        designation="Senior Cardiologist"
    )
    staff2 = HospitalStaff(
        user_id=staff_user2.id,
        hospital_id=hospital2.id,
        designation="ICU Nurse-in-Charge"
    )
    db.add_all([staff1, staff2])

    # 4. Create Wards & Beds
    h1_icu = Ward(hospital_id=hospital1.id, name="ICU Block A", ward_type="ICU")
    h1_gen = Ward(hospital_id=hospital1.id, name="General Ward 1", ward_type="GENERAL")
    db.add_all([h1_icu, h1_gen])
    db.commit()

    # Beds for Hospital 1 ICU
    for i in range(1, 6):
        status = BedStatus.AVAILABLE if i != 3 else BedStatus.OCCUPIED
        db.add(Bed(ward_id=h1_icu.id, bed_number=f"ICU-A{i:02d}", status=status))
    # Beds for Hospital 1 General
    for i in range(1, 11):
        status = BedStatus.AVAILABLE if i > 3 else BedStatus.OCCUPIED
        db.add(Bed(ward_id=h1_gen.id, bed_number=f"G1-{i:02d}", status=status))

    # Hospital 2 Wards
    h2_icu = Ward(hospital_id=hospital2.id, name="ICU Wing B", ward_type="ICU")
    db.add(h2_icu)
    db.commit()

    for i in range(1, 4):
        db.add(Bed(ward_id=h2_icu.id, bed_number=f"ICU-B{i:02d}", status=BedStatus.AVAILABLE))

    # 5. Create Resources
    db.add(Resource(hospital_id=hospital1.id, name="Mechanical Ventilator", resource_type="VENTILATOR", total_quantity=8, available_quantity=5))
    db.add(Resource(hospital_id=hospital1.id, name="Oxygen Concentrator", resource_type="OXYGEN", total_quantity=15, available_quantity=12))
    db.add(Resource(hospital_id=hospital2.id, name="Mechanical Ventilator", resource_type="VENTILATOR", total_quantity=4, available_quantity=3))

    # 6. Create Ambulances
    db.add(Ambulance(hospital_id=hospital1.id, plate_number="DL 1CA 1234", driver_name="Rajesh Singh", driver_phone="+919999911111", is_available=True, latitude=28.6140, longitude=77.2092))
    db.add(Ambulance(hospital_id=hospital1.id, plate_number="DL 1CB 5678", driver_name="Sanjay Dutt", driver_phone="+919999922222", is_available=False, latitude=28.6150, longitude=77.2100))
    db.add(Ambulance(hospital_id=hospital2.id, plate_number="HR 26AA 9999", driver_name="Ramesh Kumar", driver_phone="+919999933333", is_available=True, latitude=28.4600, longitude=77.0270))

    db.commit()
    print("Database seeding completed successfully!")

def init_db():
    print("Connecting to database and creating tables...")
    try:
        # Create all tables defined on Base metadata
        Base.metadata.create_all(bind=engine)
        print("Tables created successfully!")
        
        # Seed initial data
        db = SessionLocal()
        try:
            seed_data(db)
        finally:
            db.close()
            
    except Exception as e:
        print(f"Error initializing database: {e}")

if __name__ == "__main__":
    init_db()
