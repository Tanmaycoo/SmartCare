# SmartCare — Product Requirements Document

## 1. Product Name

SmartCare

### Project Title

Real-Time Hospital Resource & Emergency Management System

---

# 2. Product Vision

SmartCare is a real-time hospital resource and emergency management platform designed to connect patients, hospital staff, and system administrators.

The system allows hospital staff to register their hospital, manage hospital beds and resources, while system administrators verify and approve hospitals before they become available to patients.

Patients can then discover approved hospitals and view their available resources.

The long-term goal is to reduce manual communication and improve the availability of real-time hospital resource information.

---

# 3. Problem Statement

During emergencies, patients and their relatives may have difficulty finding hospitals with available beds and required resources.

Hospitals may also manage resource information manually, making it difficult to provide accurate and up-to-date availability.

SmartCare aims to provide a centralized system where:

- Hospital staff manage hospital information and resources.
- System administrators verify hospitals.
- Patients view approved hospitals.
- Patients can check available beds and resources.
- Emergency users can find suitable hospitals faster.

---

# 4. Target Users

SmartCare has three primary user roles:

1. Patient
2. Hospital Staff
3. System Administrator

---

# 5. User Roles

## 5.1 Patient

Patients use SmartCare to find and request hospital resources.

### Patient capabilities

Patients can:

- Register
- Login
- View approved hospitals
- Search hospitals
- View hospital details
- View bed availability
- View hospital resources
- Find nearby hospitals
- Request an available bed
- Track bed requests
- Receive notifications
- Use emergency mode

### Patient restriction

Patients must NOT see hospitals that have not been approved by the System Administrator.

Only hospitals with:

    status = APPROVED

should be visible to patients.

---

# 5.2 Hospital Staff

Hospital Staff are responsible for registering and managing their hospital.

### Hospital Staff capabilities

Hospital Staff can:

- Register/Add a hospital
- Enter hospital information
- Update hospital information
- View their hospital
- Add beds
- Edit beds
- Update bed status
- Manage hospital resources
- View patient requests
- Respond to bed requests
- View hospital dashboard

### Hospital Staff restriction

Hospital Staff can manage only the hospital(s) assigned to them.

They cannot:

- Approve their own hospital
- Approve another hospital
- Approve/reject hospitals
- Manage System Administrator accounts

---

# 5.3 System Administrator

The System Administrator is responsible for platform-level management and hospital verification.

### System Administrator capabilities

System Admin can:

- Login
- View all hospitals
- View pending hospitals
- Review hospital information
- Approve hospitals
- Reject hospitals
- Activate/deactivate hospitals
- Manage users
- Monitor hospital activity
- Monitor resources
- View system analytics

### Hospital approval workflow

When Hospital Staff add a hospital:

    Hospital Staff
          ↓
    Add Hospital
          ↓
       PENDING
          ↓
    System Admin Review
          ↓
      ┌─────────┐
      ↓         ↓
   APPROVE    REJECT
      ↓         ↓
   APPROVED   REJECTED
      ↓
 Visible to Patients

---

# 6. Hospital Registration

Hospital Staff can submit a hospital registration request.

### Required information

- Hospital Name
- Address
- City
- State
- Postal Code
- Phone
- Email
- Latitude
- Longitude
- Emergency Availability
- Hospital Facilities

### Initial status

Every newly registered hospital must have:

    status = PENDING

The hospital must not be visible to patients while its status is PENDING.

---

# 7. Hospital Approval

System Administrator reviews pending hospitals.

## Approval

When approved:

    status = APPROVED

The hospital becomes visible to patients.

## Rejection

When rejected:

    status = REJECTED

The hospital remains unavailable to patients.

The System Administrator may optionally provide a rejection reason.

---

# 8. Hospital Bed Management

Hospital Staff manage beds belonging to their hospital.

### Bed information

Each bed can contain:

- Bed ID
- Bed Number
- Ward
- Bed Type
- Status
- Last Updated

### Bed types

Examples:

- General
- ICU
- Emergency
- Private
- Semi-Private

### Bed statuses

    AVAILABLE
    OCCUPIED
    RESERVED
    MAINTENANCE

---

# 9. Bed Management Workflow

Hospital Staff:

    Login
       ↓
    Hospital Dashboard
       ↓
    Manage Beds
       ↓
    Add/Edit Bed
       ↓
    Update Bed Status

Example:

    ICU-01
    AVAILABLE

Hospital Staff changes:

    ICU-01
    OCCUPIED

The database is updated.

In the future, the patient application should receive the updated availability in real time.

---

# 10. Patient Hospital Discovery

Patients can search approved hospitals.

The system can provide:

- Hospital name
- Location
- Distance
- Emergency availability
- Available beds
- ICU availability
- Other resources
- Last updated time

Only approved hospitals should appear.

Query logic should effectively follow:

    hospital.status = APPROVED

---

# 11. Emergency Mode

SmartCare should provide an emergency mode for users who urgently need hospital resources.

The patient can select:

- ICU
- Emergency Bed
- Ventilator
- Oxygen
- Other required resources

The system can recommend suitable approved hospitals based on:

- Required resource
- Resource availability
- Distance
- Hospital status
- Last update time

---

# 12. Bed Request System

Patients can request available beds.

### Patient workflow

    Select Hospital
          ↓
    Select Bed/Resource
          ↓
    Submit Request
          ↓
       PENDING
          ↓
    Hospital Staff
          ↓
    ACCEPT / REJECT

### Request statuses

    PENDING
    ACCEPTED
    REJECTED
    CANCELLED
    COMPLETED

---

# 13. Notifications

SmartCare should provide notifications for important events.

Examples:

- Hospital registration approved
- Hospital registration rejected
- Bed request submitted
- Bed request accepted
- Bed request rejected
- Required bed becomes available
- Emergency updates

---

# 14. Real-Time Availability

One of SmartCare's major features is real-time resource availability.

Example:

Hospital Staff:

    ICU Bed 12
    AVAILABLE → OCCUPIED

System:

    PostgreSQL updated
          ↓
    Backend event
          ↓
    Real-time update
          ↓
    Patient application

The patient should see the updated availability without manually refreshing where real-time functionality is implemented.

---

# 15. Hospital Dashboard

Hospital Staff should have a dashboard containing:

### Hospital Overview

- Hospital name
- Approval status
- Emergency availability
- Total beds
- Available beds
- Occupied beds

### Bed Management

- Total beds
- Available
- Occupied
- Reserved
- Maintenance

### Quick Actions

- Add Hospital
- Manage Hospital
- Add Bed
- Manage Beds
- Update Bed Status
- View Requests

---

# 16. System Administrator Dashboard

The System Administrator dashboard should contain:

### Hospital Management

- Total hospitals
- Pending hospitals
- Approved hospitals
- Rejected hospitals
- Inactive hospitals

### Actions

- Review hospital
- Approve hospital
- Reject hospital
- Activate hospital
- Deactivate hospital

### User Management

- Patients
- Hospital Staff
- System Administrators

---

# 17. Technology Stack

## Mobile Application

Flutter

Dart

Android Studio

---

## Backend

Python

FastAPI

SQLAlchemy

---

## Database

PostgreSQL

---

## Authentication

JWT

Password hashing

Role-based authorization

---

## Deployment

Render

---

## Future Technologies

WebSockets

Push Notifications

Google Maps API

AI/ML

Hospital API Integration

---

# 18. Database Core Entities

The initial database should contain entities such as:

    users
    hospitals
    hospital_staff
    wards
    beds
    bed_status_history
    bed_requests
    notifications

Future entities may include:

    hospital_resources
    ambulances
    emergency_requests
    analytics

---

# 19. Security Requirements

SmartCare must:

- Hash passwords
- Use JWT authentication
- Implement role-based authorization
- Protect hospital management APIs
- Protect System Administrator APIs
- Use HTTPS in production
- Store secrets in environment variables
- Never expose database credentials
- Never expose JWT secrets
- Validate user input

---

# 20. Hospital Data Ownership

Hospital Staff should only manage data belonging to their assigned hospital.

Example:

Hospital Staff A
        ↓
Hospital A
        ↓
Beds of Hospital A

Hospital Staff A must not be able to modify:

Hospital B
or
Hospital B's beds.

System Administrator can manage all hospitals.

---

# 21. Hospital Visibility Rule

This is a critical business rule.

### PENDING

Visible to:

- Hospital Staff who registered it
- System Administrator

Not visible to:

- Patients

### APPROVED

Visible to:

- Hospital Staff
- System Administrator
- Patients

### REJECTED

Visible to:

- Hospital Staff
- System Administrator

Not visible to:

- Patients

### INACTIVE

Not visible to:

- Patients

---

# 22. Future Hospital Database Integration

The long-term SmartCare system should reduce manual data entry by integrating with existing hospital systems where technically and legally appropriate.

Possible integration methods:

- Hospital APIs
- Secure data synchronization
- HL7/FHIR-compatible interfaces
- Scheduled data imports
- Hospital-specific integration adapters

The integration layer should be separated from the core SmartCare application.

For the initial student project, hospital staff will manually register the hospital and manage beds through SmartCare.

---

# 23. Non-Functional Requirements

## Performance

The application should provide fast API responses under normal conditions.

## Reliability

The system should handle:

- Network failures
- API failures
- Database failures
- Invalid requests

## Scalability

The architecture should support:

- Multiple hospitals
- Multiple hospital staff
- Large numbers of patients
- Increasing resource records

## Maintainability

The system should use:

- Modular backend architecture
- Centralized API configuration
- Reusable Flutter components
- Database migrations
- Clear documentation

---

# 24. MVP Definition

The SmartCare MVP is considered complete when:

### Authentication

- Patient login works
- Hospital Staff login works
- System Admin login works

### Hospital

- Hospital Staff can add a hospital
- Hospital starts as PENDING
- System Admin can review hospital
- System Admin can approve/reject hospital
- Approved hospital becomes visible to patients

### Beds

- Hospital Staff can add beds
- Hospital Staff can edit beds
- Hospital Staff can update bed status
- Patients can view available beds

### Patient

- Patient can view approved hospitals
- Patient can view hospital details
- Patient can view bed availability
- Patient can request a bed

---

# 25. Development Priority

The development order should be:

1. Stabilize Authentication
2. Stabilize Hospital Registration
3. Hospital Approval
4. Hospital Staff Authorization
5. Bed Management
6. Patient Hospital Listing
7. Patient Bed Availability
8. Bed Requests
9. Notifications
10. Real-Time Updates
11. Maps
12. Emergency Mode
13. Analytics
14. AI/ML
15. External Hospital Integration

---

# 26. Success Criteria

SmartCare should provide a complete flow:

Hospital Staff
      ↓
Register Hospital
      ↓
PENDING
      ↓
System Admin
      ↓
Approve
      ↓
APPROVED
      ↓
Hospital Staff
      ↓
Add/Manage Beds
      ↓
Patient
      ↓
View Hospital
      ↓
View Available Beds
      ↓
Request Bed

This workflow is the foundation of the SmartCare system.