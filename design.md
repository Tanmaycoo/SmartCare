# SmartCare — UI/UX Design Document

# 1. Design Goal

SmartCare should look:

- Professional
- Clean
- Modern
- Simple
- Trustworthy
- Easy to use during emergencies

The interface should not look like a complicated hospital ERP system.

---

# 2. Role-Based Application

The application should provide different interfaces depending on role.

## Patient

Patient-focused interface.

## Hospital Staff

Hospital management interface.

## System Admin

System administration interface.

---

# 3. Patient Navigation

Bottom navigation:

    Home
    Hospitals
    Requests
    Notifications
    Profile

---

# 4. Patient Home

Example:

--------------------------------

Good Morning

Find a Hospital

[ Search hospitals ]

🚨 Emergency Assistance

Nearby Hospitals

ABC Hospital
2.4 km
ICU: 5 Available

XYZ Hospital
4.1 km
Emergency: Available

--------------------------------

---

# 5. Patient Hospital List

Only approved hospitals appear.

Each hospital should show:

Hospital Name
Distance
Location
Emergency Status
Available Beds
Last Updated

Example:

--------------------------------

ABC Hospital

2.4 km away

ICU
5 Available

General
23 Available

Emergency
Available

[View Details]

--------------------------------

---

# 6. Hospital Details

Show:

Hospital Name
Address
Phone
Distance
Emergency availability

Resources:

ICU
General Beds
Emergency Beds
Ventilators
Oxygen

Actions:

[Request Bed]

[Call]

[Directions]

---

# 7. Hospital Staff Navigation

Hospital Staff should have:

    Dashboard
    Hospital
    Wards
    Beds
    Requests
    Notifications
    Profile

---

# 8. Hospital Staff Dashboard

Example:

--------------------------------

Hospital Dashboard

Hospital:
ABC Hospital

Status:
● APPROVED

Beds

Total
100

Available
24

Occupied
71

Maintenance
5

Quick Actions:

[Manage Hospital]

[Manage Wards]

[Manage Beds]

[Requests]

--------------------------------

---

# 9. Add Hospital Screen

Hospital Staff should see:

--------------------------------

Add Hospital

Hospital Name
[____________]

Address
[____________]

City
[____________]

State
[____________]

Postal Code
[____________]

Phone
[____________]

Email
[____________]

Emergency Available
[ Yes / No ]

Facilities

[ ICU ]
[ Emergency ]
[ Ventilator ]
[ Oxygen ]

[Submit Hospital]

--------------------------------

After submission:

--------------------------------

Hospital submitted successfully.

Status:

PENDING

Waiting for System Administrator approval.

--------------------------------

---

# 10. Hospital Pending Screen

Hospital Staff should clearly see:

--------------------------------

Hospital Status

● PENDING

Your hospital registration is being
reviewed by the System Administrator.

You can manage your hospital information
but patients cannot see the hospital yet.

--------------------------------

---

# 11. Hospital Approved Screen

--------------------------------

Hospital Status

● APPROVED

Your hospital is now visible to patients.

[Manage Beds]

--------------------------------

---

# 12. Hospital Rejected Screen

--------------------------------

Hospital Status

● REJECTED

Reason:

Hospital information requires verification.

[Update Information]

[Resubmit]

--------------------------------

---

# 13. System Admin Navigation

System Admin:

    Dashboard
    Hospitals
    Pending Approvals
    Users
    Analytics
    Notifications
    Settings

---

# 14. Admin Dashboard

Example:

--------------------------------

System Dashboard

Hospitals

Total       35
Pending      4
Approved    28
Rejected     2
Inactive     1

Users

Patients
1,250

Hospital Staff
82

Pending Approvals

ABC Hospital
XYZ Hospital

[Review]

--------------------------------

---

# 15. Admin Hospital Approval Screen

Example:

--------------------------------

Hospital Verification

ABC Hospital

Address:
Pune, Maharashtra

Phone:
XXXXXXXXXX

Email:
hospital@example.com

Emergency:
Available

Facilities:
ICU
Emergency
Ventilator

Status:

● PENDING

Actions:

[ APPROVE ]

[ REJECT ]

--------------------------------

If rejected:

Show:

Rejection Reason

[________________]

[Confirm Rejection]

---

# 16. Bed Management Screen

Hospital Staff:

--------------------------------

Manage Beds

Ward: ICU

Beds:

ICU-01
AVAILABLE

ICU-02
OCCUPIED

ICU-03
MAINTENANCE

ICU-04
AVAILABLE

[+ Add Bed]

--------------------------------

---

# 17. Add Bed Screen

Fields:

Bed Number
Ward
Bed Type
Status

Example:

Bed Number:
ICU-05

Ward:
ICU

Type:
ICU

Status:
AVAILABLE

[Save Bed]

---

# 18. Bed Status UI

Use semantic indicators.

AVAILABLE
→ clearly indicate available

OCCUPIED
→ clearly indicate occupied

RESERVED
→ clearly indicate reserved

MAINTENANCE
→ clearly indicate maintenance

Do not rely only on color.

Always include:

- Text
- Icon
- Status indicator

---

# 19. Bed Management Permissions

Hospital Staff:

    Add Bed
    Edit Bed
    Update Status

Patient:

    View Only

System Admin:

    View All

System Admin may manage hospital-level data when required by administrative functionality.

---

# 20. Patient Bed Availability

Example:

--------------------------------

ABC Hospital

ICU

8 Available

General

24 Available

Emergency

3 Available

Last Updated:
30 seconds ago

--------------------------------

---

# 21. Emergency Screen

The emergency screen should be simple.

--------------------------------

🚨 Emergency Assistance

What do you need?

[ ICU ]

[ Emergency Bed ]

[ Ventilator ]

[ Oxygen ]

[ FIND AVAILABLE HOSPITAL ]

--------------------------------

Do not overload this screen with unnecessary information.

---

# 22. Bed Request Screen

--------------------------------

Request Bed

Hospital:
ABC Hospital

Type:
ICU

Available:
5

Patient Information

[Submit Request]

--------------------------------

---

# 23. Request Status

--------------------------------

Bed Request

ABC Hospital

ICU Bed

Status:

● Request Submitted
● Hospital Reviewing
○ Accepted

--------------------------------

---

# 24. Notifications

Examples:

"Your hospital registration has been approved."

"Your hospital registration was rejected."

"Your ICU bed request was accepted."

"ICU availability changed at ABC Hospital."

---

# 25. Loading States

Every API screen must support:

Loading

Success

Empty

Error

Example:

Loading:

    Loading hospitals...

Empty:

    No approved hospitals found.

Error:

    Unable to load hospitals.
    [Retry]

---

# 26. Error UI

Errors should be understandable.

Examples:

Network:

    Unable to connect to SmartCare.
    Please check your internet connection.

401:

    Invalid email or password.

403:

    You don't have permission to perform this action.

404:

    Hospital not found.

500:

    Server error.
    Please try again later.

---

# 27. Design Principles

Use:

- Clear hierarchy
- Consistent spacing
- Simple forms
- Large touch targets
- Readable typography
- Consistent icons
- Accessible status indicators

Avoid:

- Excessive cards
- Unnecessary animations
- Tiny buttons
- Crowded screens
- Long forms where unnecessary

---

# 28. Responsive Design

Flutter screens should work on:

- Small Android phones
- Medium Android phones
- Large Android phones
- Tablets where practical

Avoid fixed screen dimensions.

Use:

- Expanded
- Flexible
- SafeArea
- SingleChildScrollView
- Responsive layouts

where appropriate.

---

# 29. Emergency UX Rule

Emergency actions must always be easy to find.

The Emergency option should be accessible from the Patient Home screen.

However, SmartCare must clearly communicate that the application is a resource-discovery system and does not replace emergency medical services.

---

# 30. Future Real-Time UI

When bed status changes:

    AVAILABLE
        ↓
    OCCUPIED

The patient screen should update automatically.

Example:

Before:

    ICU
    5 Available

After:

    ICU
    4 Available

Show:

    Last Updated: Just now

---

# 31. Final Main User Flows

## Hospital Staff

Login
 ↓
Dashboard
 ↓
Add Hospital
 ↓
PENDING
 ↓
Admin Approval
 ↓
APPROVED
 ↓
Manage Wards
 ↓
Manage Beds
 ↓
Update Availability

---

## System Admin

Login
 ↓
Dashboard
 ↓
Pending Hospitals
 ↓
Review Hospital
 ↓
Approve / Reject
 ↓
Monitor Hospitals

---

## Patient

Login
 ↓
Home
 ↓
Approved Hospitals
 ↓
Hospital Details
 ↓
Available Beds
 ↓
Request Bed
 ↓
Track Request

---

# 32. Core UX Principle

The application should always make the user's next action obvious.

Hospital Staff:
"Add Hospital" → "Manage Beds"

System Admin:
"Review Pending Hospital" → "Approve/Reject"

Patient:
"Find Hospital" → "View Availability" → "Request Bed"