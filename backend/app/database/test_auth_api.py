"""
Test script for SmartCare authentication API endpoints.
Run with: python -m app.database.test_auth_api

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

def test_health():
    separator("TEST 1: Health Check")
    try:
        r = requests.get(f"{BASE_URL}/health")
        print(f"Status: {r.status_code}")
        print(f"Response: {r.json()}")
        assert r.status_code == 200
        assert r.json()["status"] == "ok"
        print("PASSED")
    except requests.ConnectionError:
        print("FAILED - Backend is not running. Start with: uvicorn app.main:app --reload")
        sys.exit(1)

def test_register():
    separator("TEST 2: Register New Patient")
    r = requests.post(f"{BASE_URL}/auth/register", json={
        "email": "testpatient@example.com",
        "password": "test123456",
        "full_name": "Test Patient",
        "phone": "+911234567890",
        "role": "patient"
    })
    print(f"Status: {r.status_code}")
    print(f"Response: {r.json()}")
    if r.status_code == 201:
        print("PASSED - New user created")
    elif r.status_code == 400 and "already registered" in r.json().get("detail", ""):
        print("PASSED - User already exists (expected on re-run)")
    else:
        print(f"FAILED - Unexpected response: {r.status_code}")
        return False
    return True

def test_register_duplicate():
    separator("TEST 3: Register Duplicate Email")
    r = requests.post(f"{BASE_URL}/auth/register", json={
        "email": "testpatient@example.com",
        "password": "test123456",
        "full_name": "Test Patient Duplicate",
        "phone": "+911234567891",
        "role": "patient"
    })
    print(f"Status: {r.status_code}")
    print(f"Response: {r.json()}")
    assert r.status_code == 400
    print("PASSED - Duplicate registration blocked")

def test_register_bad_password():
    separator("TEST 4: Register With Short Password")
    r = requests.post(f"{BASE_URL}/auth/register", json={
        "email": "short@example.com",
        "password": "123",
        "full_name": "Short Pass",
        "phone": "+911234567892",
        "role": "patient"
    })
    print(f"Status: {r.status_code}")
    print(f"Response: {r.json()}")
    assert r.status_code == 422
    print("PASSED - Short password rejected by validation")

def test_login_success():
    separator("TEST 5: Login With Correct Credentials")
    r = requests.post(f"{BASE_URL}/auth/login", json={
        "email": "testpatient@example.com",
        "password": "test123456"
    })
    print(f"Status: {r.status_code}")
    data = r.json()
    print(f"Response: {data}")
    assert r.status_code == 200
    assert "access_token" in data
    print("PASSED - JWT token received")
    return data["access_token"]

def test_login_wrong_password():
    separator("TEST 6: Login With Wrong Password")
    r = requests.post(f"{BASE_URL}/auth/login", json={
        "email": "testpatient@example.com",
        "password": "wrongpassword"
    })
    print(f"Status: {r.status_code}")
    print(f"Response: {r.json()}")
    assert r.status_code == 401
    print("PASSED - Wrong password rejected")

def test_me_authenticated(token):
    separator("TEST 7: Get Profile With Valid Token")
    r = requests.get(f"{BASE_URL}/auth/me", headers={
        "Authorization": f"Bearer {token}"
    })
    print(f"Status: {r.status_code}")
    print(f"Response: {r.json()}")
    assert r.status_code == 200
    assert r.json()["email"] == "testpatient@example.com"
    assert r.json()["role"] == "patient"
    print("PASSED - Authenticated profile returned")

def test_me_unauthorized():
    separator("TEST 8: Get Profile Without Token")
    r = requests.get(f"{BASE_URL}/auth/me")
    print(f"Status: {r.status_code}")
    print(f"Response: {r.json()}")
    assert r.status_code == 401
    print("PASSED - Unauthenticated access blocked")

def test_me_bad_token():
    separator("TEST 9: Get Profile With Invalid Token")
    r = requests.get(f"{BASE_URL}/auth/me", headers={
        "Authorization": "Bearer fake.invalid.token"
    })
    print(f"Status: {r.status_code}")
    print(f"Response: {r.json()}")
    assert r.status_code == 401
    print("PASSED - Invalid token rejected")

if __name__ == "__main__":
    print("\nSmartCare Authentication API Test Suite")
    print("=" * 60)
    
    test_health()
    test_register()
    test_register_duplicate()
    test_register_bad_password()
    token = test_login_success()
    test_login_wrong_password()
    test_me_authenticated(token)
    test_me_unauthorized()
    test_me_bad_token()
    
    separator("ALL TESTS PASSED")
    print("Authentication system is working correctly!")
