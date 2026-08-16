# SmartCare — Development Phases

# Phase 1 — Project Foundation

STATUS: COMPLETED

## Completed

- Flutter project
- Dart
- Android Studio
- FastAPI backend
- PostgreSQL
- Git/GitHub
- Basic project structure
- Environment configuration

---

# Phase 2 — Flutter Application Foundation

STATUS: COMPLETED

## Completed

- Flutter application
- Android configuration
- Basic navigation
- Login screen
- Registration screen
- Home screen
- Profile foundation
- API service foundation
- Mobile application running on Android device

---

# Phase 3 — Authentication

STATUS: COMPLETED / STABILIZATION

## Backend

- User model
- User registration
- Login
- Password hashing
- JWT
- Role-based authorization

## Roles

PATIENT
HOSPITAL_STAFF
SYSTEM_ADMIN

## Required Verification

- Local login
- Cloud login
- JWT persistence
- Invalid credentials
- Role authorization

---

# Phase 4 — Hospital Management

STATUS: CURRENT PHASE

## 4.1 Hospital Staff Registration

Hospital Staff can:

- Add hospital
- Enter hospital details
- Submit hospital registration

New hospital:

    PENDING

---

# 4.2 System Admin Approval

System Admin can:

- View pending hospitals
- Open hospital details
- Approve hospital
- Reject hospital

Approval:

    PENDING → APPROVED

Rejection:

    PENDING → REJECTED

---

# 4.3 Hospital Visibility

Patients only see:

    APPROVED

Hospitals with:

    PENDING
    REJECTED
    INACTIVE

must not appear in patient hospital search.

---

# 4.4 Hospital Staff Ownership

Hospital Staff can manage only their assigned hospital.

They can:

- View hospital
- Edit hospital
- Manage hospital information

They cannot:

- Approve hospital
- Reject hospital
- Modify another hospital

---

# 4.5 Phase 4 Definition of Done

Authentication works.

Hospital Staff can add hospital.

Hospital starts as PENDING.

System Admin can see pending hospital.

System Admin can approve hospital.

Approved hospital becomes visible to patients.

System Admin can reject hospital.

Rejected hospital is hidden from patients.

Hospital ownership authorization works.

---

# Phase 5 — Bed Management

STATUS: NEXT

## Objective

Allow Hospital Staff to manage beds belonging to their hospital.

---

# 5.1 Ward Management

Hospital Staff can:

- Add ward
- Edit ward
- View ward
- Disable ward

Ward information:

- Name
- Type
- Floor
- Capacity

---

# 5.2 Bed Management

Hospital Staff can:

- Add bed
- Edit bed
- Delete/disable bed
- Update bed status
- View bed

Bed information:

- Bed number
- Bed type
- Ward
- Status

---

# 5.3 Bed Types

Initial types:

GENERAL
ICU
EMERGENCY
PRIVATE
SEMI_PRIVATE

---

# 5.4 Bed Status

Initial statuses:

AVAILABLE
OCCUPIED
RESERVED
MAINTENANCE

---

# 5.5 Bed Authorization

When Hospital Staff modifies a bed:

Backend verifies:

    User
     ↓
    Hospital Staff
     ↓
    Hospital
     ↓
    Ward
     ↓
    Bed

If relationship is invalid:

    403 Forbidden

---

# 5.6 Hospital Dashboard

Hospital Staff dashboard:

    Hospital Status
    Total Beds
    Available
    Occupied
    Reserved
    Maintenance

Actions:

    Manage Hospital
    Manage Wards
    Manage Beds

---

# Phase 6 — Patient Hospital & Bed Availability

STATUS: PLANNED

Patient can:

- Search hospitals
- View approved hospitals
- View hospital details
- View bed availability
- Filter by bed type
- View last updated time

Only APPROVED hospitals are displayed.

---

# Phase 7 — Bed Request

STATUS: PLANNED

Patient:

    Select Hospital
        ↓
    Select Bed/Resource
        ↓
    Request
        ↓
    PENDING

Hospital Staff:

    ACCEPT
    REJECT

Request states:

PENDING
ACCEPTED
REJECTED
CANCELLED
COMPLETED

---

# Phase 8 — Real-Time Bed Availability

STATUS: PLANNED

Technology:

WebSockets

Flow:

Hospital Staff
    ↓
Update Bed
    ↓
FastAPI
    ↓
PostgreSQL
    ↓
WebSocket
    ↓
Patient

Example:

AVAILABLE
    ↓
OCCUPIED

Patient receives updated availability.

---

# Phase 9 — Notifications

STATUS: PLANNED

Notifications:

- Hospital approved
- Hospital rejected
- Bed request submitted
- Request accepted
- Request rejected
- Bed availability changed
- Emergency notification

---

# Phase 10 — Maps & Nearby Hospitals

STATUS: PLANNED

Features:

- GPS location
- Nearby hospitals
- Distance
- Directions
- Hospital filters

Filters:

ICU
Emergency
Ventilator
Oxygen

---

# Phase 11 — Emergency Mode

STATUS: PLANNED

Patient selects:

Emergency

Required:

ICU
Emergency Bed
Ventilator
Oxygen

System recommends approved hospitals using:

- Availability
- Distance
- Hospital status
- Last update

---

# Phase 12 — Hospital Resource Management

STATUS: PLANNED

Resources:

- ICU
- Ventilator
- Oxygen
- Emergency
- General

Hospital Staff manage:

- Total
- Available
- Occupied
- Maintenance

---

# Phase 13 — Hospital Database Integration

STATUS: FUTURE

Goal:

Reduce manual hospital data entry.

Possible integration:

- REST API
- HL7
- FHIR
- Secure synchronization
- Scheduled imports

Architecture:

Hospital System
    ↓
Integration Adapter
    ↓
SmartCare
    ↓
PostgreSQL

---

# Phase 14 — Analytics

STATUS: FUTURE

Hospital analytics:

- Occupancy
- Bed utilization
- Requests
- Emergency cases
- Resource utilization

System Admin analytics:

- Hospitals
- Users
- Hospital activity
- Regional demand

---

# Phase 15 — AI/ML

STATUS: FUTURE

Potential features:

- Bed demand prediction
- Resource demand prediction
- Hospital recommendation
- Emergency demand prediction

AI must only be added after reliable historical data is available.

---

# Phase 16 — Testing

STATUS: FUTURE

## Backend

- Unit tests
- API tests
- Authentication tests
- Authorization tests
- Database tests

## Flutter

- Widget tests
- Integration tests
- Network error tests

## Security

- Unauthorized access
- Role escalation
- Hospital ownership
- API validation

---

# Phase 17 — Production Release

STATUS: FUTURE

Backend:

Render

Database:

Render PostgreSQL

Mobile:

Flutter Android Release

Build:

flutter build apk --release

---

# CURRENT DEVELOPMENT ORDER

Do NOT skip directly to AI/ML.

Current order:

    Phase 4
    Hospital Approval
         ↓
    Phase 5
    Bed Management
         ↓
    Phase 6
    Patient Availability
         ↓
    Phase 7
    Bed Requests
         ↓
    Phase 8
    Real-Time
         ↓
    Phase 9
    Notifications
         ↓
    Phase 10
    Maps
         ↓
    Phase 11
    Emergency Mode
         ↓
    Phase 12
    Resources
         ↓
    Phase 13
    Integration
         ↓
    Phase 14
    Analytics
         ↓
    Phase 15
    AI/ML