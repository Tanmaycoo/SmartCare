# SmartCare — Development Rules

## 1. General Development Rules

1. Do not rebuild the project from scratch.
2. Preserve existing working functionality.
3. Inspect existing code before modifying it.
4. Make the smallest reliable changes.
5. Do not delete database data without explicit approval.
6. Do not create duplicate APIs or models.
7. Follow the project architecture.
8. Test every major change.

---

# 2. User Role Rules

SmartCare has three main roles:

PATIENT
HOSPITAL_STAFF
SYSTEM_ADMIN

Role permissions must always be enforced by the backend.

---

# 3. Hospital Registration Rules

Hospital Staff can add/register a hospital.

When a hospital is created:

    status = PENDING

A newly created hospital must NOT automatically become visible to patients.

---

# 4. Hospital Approval Rules

Only SYSTEM_ADMIN can approve a hospital.

Hospital Staff cannot approve their own hospital.

Hospital Staff cannot approve another hospital.

When System Admin approves:

    PENDING → APPROVED

When System Admin rejects:

    PENDING → REJECTED

---

# 5. Hospital Visibility Rules

Patients can only see:

    status = APPROVED

Patients cannot see:

    PENDING
    REJECTED
    INACTIVE

---

# 6. Hospital Staff Ownership Rules

Hospital Staff can manage only hospitals assigned to them.

Before modifying a hospital, backend must verify:

    authenticated_user
          ↓
    hospital_staff relationship
          ↓
    requested hospital

If the user does not own/have permission for the hospital:

    HTTP 403 Forbidden

---

# 7. Bed Management Rules

Hospital Staff can:

- Add beds
- Edit beds
- Update bed status
- View beds
- Manage beds belonging to their hospital

Hospital Staff cannot modify another hospital's beds.

---

# 8. Bed Relationship Rules

Every bed must belong to:

    Bed
      ↓
    Ward
      ↓
    Hospital

Before changing a bed, verify that the authenticated staff member has access to the hospital that owns the bed.

---

# 9. Bed Status Rules

Allowed bed statuses:

    AVAILABLE
    OCCUPIED
    RESERVED
    MAINTENANCE

Do not use arbitrary status strings.

---

# 10. Patient Rules

Patients can:

- View approved hospitals
- View hospital details
- View available beds
- Submit bed requests
- View request status

Patients cannot:

- Add hospitals
- Approve hospitals
- Manage beds
- Change bed availability
- Modify hospital data

---

# 11. System Admin Rules

System Admin can:

- View all hospitals
- Review pending hospitals
- Approve hospitals
- Reject hospitals
- Activate hospitals
- Deactivate hospitals
- Manage users
- View system information

System Admin approval is required before hospital visibility.

---

# 12. Authentication Rules

Use JWT authentication.

Passwords must be hashed.

Never store plain-text passwords.

Never log:

- passwords
- JWT tokens
- SECRET_KEY
- DATABASE_URL
- authorization headers

---

# 13. API Rules

Use proper HTTP status codes.

200:
Successful request

201:
Resource created

400:
Invalid request

401:
Not authenticated

403:
Not authorized

404:
Resource not found

409:
Conflict

422:
Validation error

500:
Unexpected server error

---

# 14. API Security Rules

Never rely on Flutter to enforce authorization.

For every protected API:

    Authenticate user
          ↓
    Determine role
          ↓
    Verify permission
          ↓
    Verify resource ownership
          ↓
    Perform action

---

# 15. Database Rules

Database:

PostgreSQL

ORM:

SQLAlchemy

Use database migrations for schema changes.

Do not depend on:

    Base.metadata.create_all()

as the production migration strategy.

Never manually change production schema without recording the migration.

---

# 16. Environment Rules

Never commit:

.env

Never commit:

DATABASE_URL
SECRET_KEY
API keys
Passwords

Use:

.env.example

for variable names and placeholders.

---

# 17. Flutter Rules

Use one centralized API configuration.

Production API:

https://smartcare-api-r14o.onrender.com

Do not use production code with:

127.0.0.1
localhost
10.0.2.2

Do not scatter API URLs throughout the application.

---

# 18. Flutter State Rules

Every API request must handle:

Loading
Success
Error
Empty

No screen should remain in an infinite loading state.

Always ensure loading state is reset after request completion/failure.

---

# 19. Error Handling Rules

Do not show the same generic error for every failure.

Handle:

Network errors
401
403
404
422
500
Timeouts

User-facing errors must be understandable.

Debug logs may contain safe technical details.

Never log secrets.

---

# 20. Hospital Status Rules

Valid statuses:

PENDING
APPROVED
REJECTED
INACTIVE

Default status:

PENDING

Only System Admin can change:

PENDING → APPROVED

PENDING → REJECTED

APPROVED → INACTIVE

INACTIVE → APPROVED

---

# 21. Patient Search Rule

All patient hospital queries must filter out non-approved hospitals.

Conceptually:

    WHERE hospital.status = 'APPROVED'

Do not rely only on Flutter to hide pending hospitals.

---

# 22. Hospital Staff Dashboard Rule

Hospital Staff dashboard should show:

- Hospital status
- Hospital details
- Beds
- Bed availability
- Requests

If hospital status is PENDING:

Staff can manage submitted hospital information according to permissions.

Patients still cannot see it.

---

# 23. Admin Approval Rule

When approving a hospital:

1. Verify System Admin role.
2. Find hospital.
3. Verify current status.
4. Update status.
5. Store approver.
6. Store approval timestamp.
7. Commit transaction.

---

# 24. Audit Rule

Important administrative actions should eventually be recorded.

Examples:

- Hospital created
- Hospital approved
- Hospital rejected
- Hospital deactivated
- Bed status changed

Future table:

    audit_logs

---

# 25. Real-Time Rules

Real-time updates should only be implemented after the normal REST API is stable.

First:

    Database
    ↓
    REST API
    ↓
    Flutter

Then:

    WebSocket
    ↓
    Real-time updates

---

# 26. AI Rules

Do not add AI just for appearance.

AI should only be implemented after enough reliable data exists.

AI recommendations must not replace medical professionals or hospital decisions.

---

# 27. Deployment Rules

Render backend:

    Root Directory:
    backend

    Build:
    pip install -r requirements.txt

    Start:
    uvicorn app.main:app --host 0.0.0.0 --port $PORT

Production database:

    Render PostgreSQL

---

# 28. Git Rules

Before commit:

- Test application
- Check git diff
- Check for secrets
- Check environment files
- Check database changes

Never push credentials.

---

# 29. Change Management Rule

Before implementing a new feature:

1. Read PRD.md
2. Read architecture.md
3. Read rules.md
4. Read phases.md
5. Read design.md
6. Inspect existing code
7. Implement
8. Test
9. Update documentation if necessary

---

# 30. Most Important Business Rule

Hospital Staff:

    ADD HOSPITAL
        ↓
    PENDING

System Admin:

    REVIEW
        ↓
    APPROVE / REJECT

Only after approval:

    APPROVED
        ↓
    Visible to Patients

Hospital Staff:

    MANAGE BEDS

Patients:

    VIEW AVAILABLE BEDS