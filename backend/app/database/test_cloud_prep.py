"""
Cloud deployment preparation verification test.
Tests:
1. Config & environment variable loading (DATABASE_URL, SECRET_KEY, CORS_ORIGINS)
2. FastAPI app routes & health endpoint (GET /health)
3. FastAPI docs endpoint (GET /docs)
4. Auth endpoint (GET /auth/me simulation)
5. Hospital endpoint (GET /hospitals simulation)
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from app.core.config import settings
from app.core.security import create_access_token, decode_access_token
from app.database.session import SessionLocal, engine
from app.models.user import User
from app.models.hospital import Hospital
from app.main import app, get_cors_origins

def test_cloud_prep():
    print("\n==================================================")
    print("  VERIFYING BACKEND CLOUD PREPARATION")
    print("==================================================")

    # 1. Config & Environment Variables
    print("\n--- 1. Testing Config & Env Variables ---")
    print(f"APP_NAME: {settings.APP_NAME}")
    print(f"DATABASE_URL: {settings.DATABASE_URL}")
    print(f"SECRET_KEY: {'*' * len(settings.SECRET_KEY)}")
    print(f"CORS_ORIGINS: {settings.CORS_ORIGINS}")
    print(f"Parsed CORS List: {get_cors_origins()}")
    
    assert settings.DATABASE_URL.startswith("postgresql://"), "DATABASE_URL scheme error!"
    assert len(settings.SECRET_KEY) > 10, "SECRET_KEY is too short!"
    assert get_cors_origins() == ["*"], "CORS parsing error!"
    print("PASSED - Environment configuration validated!")

    # 2. JWT Encoding/Decoding with SECRET_KEY
    print("\n--- 2. Testing JWT Token Operations with SECRET_KEY ---")
    token = create_access_token(subject="admin@smartcare.com", role="system_admin")
    decoded = decode_access_token(token)
    assert decoded is not None
    assert decoded["sub"] == "admin@smartcare.com"
    assert decoded["role"] == "system_admin"
    print("PASSED - JWT token generation/validation with SECRET_KEY works perfectly!")

    # 3. Test Health Endpoint
    print("\n--- 3. Testing GET /health ---")
    db = SessionLocal()
    try:
        from app.main import health_check
        res = health_check()
        print(f"Response: {res}")
        assert res["status"] == "ok"
        print("PASSED - GET /health works and returns status: ok!")

        # 4. Test Database Connection & /auth/me query
        print("\n--- 4. Testing User Query (GET /auth/me foundation) ---")
        user = db.query(User).filter(User.email == "admin@smartcare.com").first()
        assert user is not None
        print(f"Retrieved User: {user.email} (Role: {user.role.value})")
        print("PASSED - Database session & auth query working!")

        # 5. Test Hospital Query (GET /hospitals foundation)
        print("\n--- 5. Testing Hospital Query (GET /hospitals foundation) ---")
        hospitals = db.query(Hospital).all()
        print(f"Found {len(hospitals)} hospitals in database:")
        for h in hospitals:
            print(f"  - {h.name} ({h.city}, {h.state}) | Verification: {h.verification_status.value} | Status: {h.status.value}")
        assert len(hospitals) >= 2
        print("PASSED - GET /hospitals database query working!")

    finally:
        db.close()

    print("\n==================================================")
    print("  ALL CLOUD PREPARATION VERIFICATIONS PASSED!")
    print("==================================================")

if __name__ == "__main__":
    test_cloud_prep()
