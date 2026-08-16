# SmartCare — System Architecture

## 1. Overview

SmartCare follows a client-server architecture.

The main components are:

1. Flutter Mobile Application
2. FastAPI Backend
3. PostgreSQL Database
4. Render Cloud Infrastructure
5. Future Real-Time Communication Layer
6. Future Hospital Integration Layer

---

# 2. High-Level Architecture

                    ┌──────────────────────┐
                    │   Flutter Mobile App  │
                    │       (Dart)          │
                    └──────────┬───────────┘
                               │
                              HTTPS
                               │
                               ▼
                    ┌──────────────────────┐
                    │    FastAPI Backend   │
                    │       Python         │
                    └──────────┬───────────┘
                               │
                    ┌──────────┴──────────┐
                    │                     │
                    ▼                     ▼
             ┌──────────────┐      ┌──────────────┐
             │  PostgreSQL  │      │  WebSocket   │
             │   Database   │      │ Future Layer │
             └──────────────┘      └──────────────┘

---

# 3. User Roles

SmartCare has three main roles:

    PATIENT
    HOSPITAL_STAFF
    SYSTEM_ADMIN

Each role has different permissions.

---

# 4. Role Architecture

## Patient

Patient
   |
   +-- Login
   +-- View Approved Hospitals
   +-- View Hospital Details
   +-- View Bed Availability
   +-- Request Bed
   +-- Track Requests
   +-- Notifications

Patient cannot:

- Add hospitals
- Approve hospitals
- Manage hospital beds
- Manage other users

---

## Hospital Staff

Hospital Staff
   |
   +-- Login
   +-- Add Hospital
   +-- Manage Hospital
   +-- Add Beds
   +-- Edit Beds
   +-- Update Bed Status
   +-- View Requests
   +-- Respond to Requests

Hospital Staff cannot:

- Approve hospitals
- Reject hospitals
- Manage System Admins
- Modify another hospital's data

---

## System Admin

System Admin
   |
   +-- Login
   +-- View Hospitals
   +-- Review Pending Hospitals
   +-- Approve Hospital
   +-- Reject Hospital
   +-- Activate Hospital
   +-- Deactivate Hospital
   +-- Manage Users
   +-- View System Analytics

---

# 5. Hospital Registration Architecture

Hospital Staff creates a hospital.

             Hospital Staff
                    |
                    ▼
             Hospital API
                    |
                    ▼
              PostgreSQL
                    |
                    ▼
          status = PENDING
                    |
                    ▼
          System Admin Dashboard
                    |
             ┌──────┴──────┐
             ▼             ▼
          APPROVE        REJECT
             |             |
             ▼             ▼
        APPROVED       REJECTED

---

# 6. Hospital Visibility Architecture

The hospital status determines visibility.

## PENDING

    Hospital Staff → YES
    System Admin → YES
    Patient → NO

## APPROVED

    Hospital Staff → YES
    System Admin → YES
    Patient → YES

## REJECTED

    Hospital Staff → YES
    System Admin → YES
    Patient → NO

## INACTIVE

    Hospital Staff → YES
    System Admin → YES
    Patient → NO

---

# 7. Hospital Ownership

Each hospital belongs to a hospital staff/admin account.

Example:

    User
      |
      | hospital_id
      ▼
    Hospital
      |
      ├── Wards
      |
      ├── Beds
      |
      └── Resources

Hospital Staff can only modify resources belonging to their authorized hospital.

---

# 8. Database Architecture

Core entities:

    users
    hospitals
    hospital_staff
    wards
    beds
    bed_status_history
    bed_requests
    notifications

---

# 9. Users

users

    id
    email
    password_hash
    full_name
    role
    is_active
    created_at
    updated_at

Roles:

    PATIENT
    HOSPITAL_STAFF
    SYSTEM_ADMIN

---

# 10. Hospitals

hospitals

    id
    name
    address
    city
    state
    postal_code
    phone
    email
    latitude
    longitude
    emergency_available
    status
    rejection_reason
    created_by
    approved_by
    approved_at
    created_at
    updated_at

Hospital status:

    PENDING
    APPROVED
    REJECTED
    INACTIVE

---

# 11. Hospital Staff Relationship

hospital_staff

    id
    user_id
    hospital_id
    created_at

Relationship:

    User
      |
      +---- Hospital Staff
                  |
                  +---- Hospital

---

# 12. Ward Architecture

wards

    id
    hospital_id
    name
    type
    floor
    capacity
    status
    created_at
    updated_at

Relationship:

    Hospital
       |
       +-- Ward
              |
              +-- Beds

---

# 13. Bed Architecture

beds

    id
    ward_id
    bed_number
    bed_type
    status
    patient_reference
    last_updated
    created_at
    updated_at

Bed types:

    GENERAL
    ICU
    EMERGENCY
    PRIVATE
    SEMI_PRIVATE

Bed statuses:

    AVAILABLE
    OCCUPIED
    RESERVED
    MAINTENANCE

---

# 14. Bed Ownership

A bed belongs to a ward.

A ward belongs to a hospital.

Therefore:

    Bed
      ↓
    Ward
      ↓
    Hospital

Hospital Staff authorization should verify this relationship before allowing bed modification.

---

# 15. Bed Management Flow

Hospital Staff:

    Login
      ↓
    Select Hospital
      ↓
    Manage Wards
      ↓
    Manage Beds
      ↓
    Add/Edit Bed
      ↓
    Update Status
      ↓
    PostgreSQL

---

# 16. Patient Availability Flow

Patient:

    Login
      ↓
    Search Hospitals
      ↓
    Backend
      ↓
    Filter:
    status = APPROVED
      ↓
    Calculate availability
      ↓
    Return hospitals
      ↓
    Flutter

---

# 17. Bed Request Architecture

Patient
   |
   | POST /bed-requests
   ▼
FastAPI
   |
   ▼
PostgreSQL
   |
   ▼
PENDING
   |
   ▼
Hospital Staff
   |
   ├── ACCEPT
   |
   └── REJECT

---

# 18. API Architecture

## Authentication

POST /auth/register
POST /auth/login
GET /auth/me

---

## Hospital

POST /hospitals
GET /hospitals
GET /hospitals/{id}
PUT /hospitals/{id}

---

## Admin Hospital Approval

GET /admin/hospitals/pending

POST /admin/hospitals/{id}/approve

POST /admin/hospitals/{id}/reject

POST /admin/hospitals/{id}/activate

POST /admin/hospitals/{id}/deactivate

---

## Beds

POST /hospitals/{hospital_id}/beds

GET /hospitals/{hospital_id}/beds

PUT /beds/{bed_id}

DELETE /beds/{bed_id}

---

## Requests

POST /bed-requests

GET /bed-requests

PUT /bed-requests/{id}

---

# 19. Authorization Architecture

Backend must enforce permissions.

Example:

    HOSPITAL_STAFF
           |
           ▼
    Can create hospital
    Can manage own hospital
    Can manage own beds

    SYSTEM_ADMIN
           |
           ▼
    Can approve/reject hospitals
    Can manage all hospitals

    PATIENT
           |
           ▼
    Can view approved hospitals
    Can request beds

Authorization must NOT rely only on Flutter UI.

---

# 20. Cloud Architecture

                    INTERNET
                       |
                       ▼
                 Flutter App
                       |
                     HTTPS
                       |
                       ▼
               Render FastAPI
                       |
                       ▼
              Render PostgreSQL

Production secrets:

    DATABASE_URL
    SECRET_KEY

must be stored as environment variables.

---

# 21. Future Real-Time Architecture

Hospital Staff
      |
      ▼
Update Bed
      |
      ▼
FastAPI
      |
      ▼
PostgreSQL
      |
      ▼
WebSocket Event
      |
      ▼
Patient Flutter App

Example:

    ICU-01
    AVAILABLE
        ↓
    Staff updates
        ↓
    OCCUPIED
        ↓
    Patient receives update

---

# 22. Future Hospital Integration

SmartCare may eventually integrate with existing hospital systems.

Architecture:

Hospital HIS
     |
     ▼
Integration Adapter
     |
     ▼
SmartCare Integration Layer
     |
     ▼
FastAPI
     |
     ▼
PostgreSQL

Possible standards:

- REST APIs
- HL7
- FHIR
- Secure data synchronization

For the initial project, hospital staff will manually manage hospital and bed information.

---

# 23. Security Architecture

Use:

- HTTPS
- JWT
- Password hashing
- Role-based access control
- Database constraints
- Input validation
- Environment variables
- Secure API authorization

Never trust role information sent only by the mobile application.

The backend must determine the authenticated user's role from the authenticated identity.

---

# 24. Main System Flow

    Hospital Staff
          |
          ▼
    Add Hospital
          |
          ▼
       PENDING
          |
          ▼
    System Admin
          |
       Approve
          |
          ▼
      APPROVED
          |
          ▼
    Hospital Staff
          |
          ▼
      Add Beds
          |
          ▼
    Update Availability
          |
          ▼
       Patient
          |
          ▼
   View Available Beds
          |
          ▼
      Request Bed