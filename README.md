# SmartCare
### Real-Time Hospital Resource & Emergency Management System

SmartCare is a real-time coordination and resource visibility layer designed for patients and emergency users to find nearby hospitals, view real-time availability of important resources (beds, ICU, ventilators, etc.), and coordinate hospital-operator and system-admin responses.

This repository is structured as a monorepo containing both the frontend client and backend service.

---

## Directory Structure

```
smartcare/
│
├── mobile/                   # Flutter Application (Material 3 Client)
│   ├── lib/
│   │   └── main.dart         # Entry & Welcome Screen
│   ├── test/
│   │   └── widget_test.dart  # UI Smoke Test
│   └── pubspec.yaml          # Flutter dependencies
│
├── backend/                  # FastAPI Application (REST API Service)
│   ├── app/
│   │   ├── main.py           # Application Entry & health endpoint
│   │   ├── core/             # Application config and settings
│   │   ├── database/         # SQLAlchemy DB connection setup
│   │   ├── models/           # SQLAlchemy DB Models (Users, Hospitals, etc.)
│   │   ├── schemas/          # Pydantic schemas (Request/Response validation)
│   │   ├── routers/          # API endpoints (Auth, Resources, etc.)
│   │   └── services/         # Real-time WebSocket services
│   ├── requirements.txt      # Python dependencies
│   ├── .env                  # Local environment file (auto-generated)
│   └── .env.example          # Environment configuration template
│
├── docs/                     # Project design docs and diagrams
├── README.md                 # Project root documentation
└── .gitignore                # Global git ignore rules
```

---

## Getting Started

### 1. Prerequisites
- **Flutter SDK**: `^3.12.2` or later
- **Python**: `3.9` or later
- **PostgreSQL**: Local database instance or container (prepared for Phase 2)

---

## How to Run

### A. FastAPI Backend Service

1. Navigate to the backend directory:
   ```bash
   cd backend
   ```
2. Install the required dependencies:
   ```bash
   pip install -r requirements.txt
   ```
3. Run the development server using Uvicorn:
   ```bash
   uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
   ```
4. Verify backend status:
   - **Health endpoint**: Navigate to `http://localhost:8000/health` (should return JSON status `"ok"`).
   - **Swagger Docs**: Open `http://localhost:8000/docs` to view interactive API documentation.

### B. Flutter Client (Mobile App)

1. Navigate to the mobile directory:
   ```bash
   cd mobile
   ```
2. Fetch dependencies:
   ```bash
   flutter pub get
   ```
3. Run the application:
   - To run on Windows:
     ```bash
     flutter run -d windows
     ```
   - To run on Chrome (web simulation):
     ```bash
     flutter run -d chrome
     ```
   - Or run inside your preferred Emulator/Simulator.
