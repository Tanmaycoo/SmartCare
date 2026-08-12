import os
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.routers import auth as auth_router
from app.routers import hospital as hospital_router
import app.models  # noqa: F401 - ensures all models are registered on Base metadata

app = FastAPI(
    title=settings.APP_NAME,
    description="Real-Time Hospital Resource & Emergency Management System API",
    version="1.0.0",
)

def get_cors_origins():
    origins_str = settings.CORS_ORIGINS.strip()
    if not origins_str or origins_str == "*":
        return ["*"]
    return [origin.strip() for origin in origins_str.split(",") if origin.strip()]

# Configure CORS (Cross-Origin Resource Sharing)
app.add_middleware(
    CORSMiddleware,
    allow_origins=get_cors_origins(),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Include routers
app.include_router(auth_router.router)
app.include_router(hospital_router.router)

@app.get("/health", tags=["Health"])
def health_check():
    return {
        "status": "ok",
        "service": "smartcare-backend"
    }

if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8000))
    uvicorn.run("app.main:app", host="0.0.0.0", port=port, reload=True)
