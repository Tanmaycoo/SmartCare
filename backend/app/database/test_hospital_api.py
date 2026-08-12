"""
Test script for SmartCare Hospital Management API endpoints.
Run with: python -m app.database.test_hospital_api

Requires:
  - PostgreSQL running (docker compose up -d)
  - Tables initialized (python -m app.database.init_db)
  - Backend running (uvicorn app.main:app --reload)
"""
import requests
import sys

BASE_URL = "http://localhost:8000"

def separator(title):
    print(f"\n{'='*60}")
    print(f"  {title}")
    print(f"{'='*60}")

def get_token(email, password):
    r = requests.post(f"{BASE_URL}/auth/login", json={"email": email, "password": password})
    if r.status_code == 200:
        return r.json()["access_token"]
    # If user doesn't exist, register user first
    role = "hospital_admin" if "hospadmin" in email else "patient"
    reg_r = requests.post(f"{BASE_URL}/auth/register", json={
        "email": email,
        "password": password,
        "full_name": email.split("@")[0].title(),
        "phone": "+919876543299",
        "role": role
    })
    r = requests.post(f"{BASE_URL}/auth/login", json={"email": email, "password": password})
    return r.json().get("access_token")

def test_hospital_creation():
    separator("TEST 1: Hospital Creation (Hospital Admin)")
    admin_token = get_token("hospadmin@citygeneral.com", "admin123")
    assert admin_token, "Failed to get token for hospital admin"

    payload = {
        "name": "Apex Heart & Super Speciality Hospital",
        "address": "789 Health Expressway, Sector 62",
        "city": "Noida",
        "state": "Uttar Pradesh",
        "postal_code": "201301",
        "phone": "0120-4455667",
        "email": "contact@apexhospital.org",
        "latitude": 28.6270,
        "longitude": 77.3725,
        "emergency_available": True
    }
    r = requests.post(f"{BASE_URL}/hospitals", json=payload, headers={"Authorization": f"Bearer {admin_token}"})
    print(f"Status: {r.status_code}")
    print(f"Response: {r.json()}")
    assert r.status_code == 201
    data = r.json()
    assert data["verification_status"] == "PENDING"
    assert data["status"] == "INACTIVE"
    print("PASSED - Hospital created with status PENDING/INACTIVE")
    return data["id"], admin_token

def test_patient_unauthorized_creation():
    separator("TEST 2: Patient Cannot Create Hospital")
    patient_token = get_token("patient@gmail.com", "patient123")
    payload = {
        "name": "Rogue Hospital",
        "address": "123 Fake St",
        "city": "Delhi",
        "state": "Delhi",
        "postal_code": "110001",
        "phone": "011-00000000",
        "email": "rogue@hospital.com",
        "latitude": 28.6,
        "longitude": 77.2,
        "emergency_available": False
    }
    r = requests.post(f"{BASE_URL}/hospitals", json=payload, headers={"Authorization": f"Bearer {patient_token}"})
    print(f"Status: {r.status_code}")
    assert r.status_code == 403
    print("PASSED - Patient creation blocked (403 Forbidden)")

def test_patient_view_active_hospitals():
    separator("TEST 3: Patient Viewing Active Verified Hospitals")
    patient_token = get_token("patient@gmail.com", "patient123")
    r = requests.get(f"{BASE_URL}/hospitals", headers={"Authorization": f"Bearer {patient_token}"})
    print(f"Status: {r.status_code}")
    hospitals = r.json()
    print(f"Hospitals returned to patient: {len(hospitals)}")
    for h in hospitals:
        assert h["verification_status"] == "VERIFIED"
        assert h["status"] == "ACTIVE"
    print("PASSED - Patient sees only VERIFIED & ACTIVE hospitals")

def test_system_admin_verification(hospital_id):
    separator("TEST 4: System Admin Verify Hospital")
    sysadmin_token = get_token("admin@smartcare.com", "admin123")
    
    # Verify hospital
    r = requests.patch(
        f"{BASE_URL}/hospitals/{hospital_id}/verify",
        json={"verification_status": "VERIFIED"},
        headers={"Authorization": f"Bearer {sysadmin_token}"}
    )
    print(f"Status: {r.status_code}")
    data = r.json()
    print(f"Response: {data}")
    assert r.status_code == 200
    assert data["verification_status"] == "VERIFIED"
    assert data["status"] == "ACTIVE"
    print("PASSED - Hospital verified and activated by System Admin")

def test_update_own_hospital(hospital_id, admin_token):
    separator("TEST 5: Hospital Admin Modifying Own Hospital")
    r = requests.put(
        f"{BASE_URL}/hospitals/{hospital_id}",
        json={"phone": "0120-9988776", "emergency_available": False},
        headers={"Authorization": f"Bearer {admin_token}"}
    )
    print(f"Status: {r.status_code}")
    data = r.json()
    print(f"Updated Phone: {data.get('phone')}")
    assert r.status_code == 200
    assert data["phone"] == "0120-9988776"
    assert data["emergency_available"] == False
    print("PASSED - Hospital updated successfully by owner")

def test_update_other_hospital_forbidden(hospital_id):
    separator("TEST 6: Hospital Admin Modifying Another Hospital (Forbidden)")
    # Register second admin
    other_admin_token = get_token("otheradmin@hospital.com", "pass123456")
    r = requests.put(
        f"{BASE_URL}/hospitals/{hospital_id}",
        json={"name": "Hacked Hospital Name"},
        headers={"Authorization": f"Bearer {other_admin_token}"}
    )
    print(f"Status: {r.status_code}")
    assert r.status_code == 403
    print("PASSED - Unauthorized hospital edit blocked (403 Forbidden)")

def test_system_admin_suspension_and_rejection(hospital_id):
    separator("TEST 7: System Admin Suspend and Reject")
    sysadmin_token = get_token("admin@smartcare.com", "admin123")
    
    # Suspend
    r1 = requests.patch(
        f"{BASE_URL}/hospitals/{hospital_id}/suspend",
        headers={"Authorization": f"Bearer {sysadmin_token}"}
    )
    assert r1.status_code == 200
    assert r1.json()["verification_status"] == "SUSPENDED"
    assert r1.json()["status"] == "INACTIVE"
    print("PASSED - Hospital suspended")

    # Activate back
    r2 = requests.patch(
        f"{BASE_URL}/hospitals/{hospital_id}/activate",
        headers={"Authorization": f"Bearer {sysadmin_token}"}
    )
    assert r2.status_code == 200
    assert r2.json()["status"] == "ACTIVE"
    print("PASSED - Hospital activated")

    # Soft Delete / Reject
    r3 = requests.delete(
        f"{BASE_URL}/hospitals/{hospital_id}",
        headers={"Authorization": f"Bearer {sysadmin_token}"}
    )
    assert r3.status_code == 200
    print("PASSED - Hospital soft deleted/deactivated")

if __name__ == "__main__":
    print("\nSmartCare Hospital Management API Test Suite")
    print("=" * 60)
    
    hospital_id, admin_token = test_hospital_creation()
    test_patient_unauthorized_creation()
    test_patient_view_active_hospitals()
    test_system_admin_verification(hospital_id)
    test_update_own_hospital(hospital_id, admin_token)
    test_update_other_hospital_forbidden(hospital_id)
    test_system_admin_suspension_and_rejection(hospital_id)
    
    separator("ALL PHASE 4 BACKEND TESTS PASSED")
    print("Hospital Management API system is fully operational!")
