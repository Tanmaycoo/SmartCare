import os
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.core.config import settings
from app.routers import auth as auth_router
from app.routers import hospital as hospital_router
from app.routers import admin as admin_router
from app.routers import beds as beds_router
from app.database.init_db import init_db
import app.models  # noqa: F401 — registers all models on Base metadata


@asynccontextmanager
async def lifespan(app: FastAPI):
    """Run DB initialisation on startup (creates tables + seeds data if empty)."""
    try:
        init_db()
    except Exception as e:
        print(f"Startup DB initialisation warning: {e}")
    yield


app = FastAPI(
    title=settings.APP_NAME,
    description="Real-Time Hospital Resource & Emergency Management System API",
    version="1.0.0",
    lifespan=lifespan,
)


def get_cors_origins():
    origins_str = settings.CORS_ORIGINS.strip()
    if not origins_str or origins_str == "*":
        return ["*"]
    return [o.strip() for o in origins_str.split(",") if o.strip()]


# CORS middleware
app.add_middleware(
    CORSMiddleware,
    allow_origins=get_cors_origins(),
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ── Routers ────────────────────────────────────────────────────────────────────
app.include_router(auth_router.router)       # /auth/*
app.include_router(hospital_router.router)   # /hospitals/*
app.include_router(admin_router.router)      # /admin/hospitals/*  (System Admin)
app.include_router(beds_router.router)       # /hospitals/{id}/wards, /wards/{id}/beds, /beds/*


# ── Root / health endpoints ────────────────────────────────────────────────────
@app.get("/", tags=["Root"])
def root():
    return {"message": "SmartCare API is running", "status": "ok"}


@app.get("/health", tags=["Health"])
def health_check():
    return {"status": "ok"}


if __name__ == "__main__":
    import uvicorn
    port = int(os.getenv("PORT", 8000))
    uvicorn.run("app.main:app", host="0.0.0.0", port=port, reload=True)
