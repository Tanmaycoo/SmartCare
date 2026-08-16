"""
migrate_phase4b.py — Safe schema migration for MD-file alignment.

Adds columns required by architecture.md that do not yet exist in the
production/local PostgreSQL database. Safe to run multiple times
(checks column existence before altering).

New columns:
  hospitals:  rejection_reason, created_by, approved_by, approved_at
  wards:      floor, capacity, ward_status
  beds:       bed_type, patient_reference

New enum types:
  bedtype        (GENERAL, ICU, EMERGENCY, PRIVATE, SEMI_PRIVATE)
  wardstatus     (ACTIVE, INACTIVE)
"""

import os
import sys

sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from sqlalchemy import text
from app.database.session import engine


def column_exists(conn, table: str, column: str) -> bool:
    result = conn.execute(text(
        "SELECT 1 FROM information_schema.columns "
        "WHERE table_name = :table AND column_name = :column"
    ), {"table": table, "column": column})
    return result.fetchone() is not None


def enum_type_exists(conn, type_name: str) -> bool:
    result = conn.execute(text(
        "SELECT 1 FROM pg_type WHERE typname = :name"
    ), {"name": type_name})
    return result.fetchone() is not None


def run_migration():
    print("=" * 60)
    print("  SmartCare — Phase 4b Schema Migration")
    print("=" * 60)

    with engine.begin() as conn:

        # ── 1. Create bedtype enum if not exists ──────────────────
        if not enum_type_exists(conn, "bedtype"):
            print("Creating enum: bedtype")
            conn.execute(text(
                "CREATE TYPE bedtype AS ENUM "
                "('GENERAL', 'ICU', 'EMERGENCY', 'PRIVATE', 'SEMI_PRIVATE')"
            ))
        else:
            print("Enum bedtype already exists — skipping")

        # ── 2. Create wardstatus enum if not exists ───────────────
        if not enum_type_exists(conn, "wardstatus"):
            print("Creating enum: wardstatus")
            conn.execute(text(
                "CREATE TYPE wardstatus AS ENUM ('ACTIVE', 'INACTIVE')"
            ))
        else:
            print("Enum wardstatus already exists — skipping")

        # ── 3. hospitals table additions ──────────────────────────
        print("\n--- Updating hospitals table ---")

        if not column_exists(conn, "hospitals", "rejection_reason"):
            print("  ADD rejection_reason (TEXT)")
            conn.execute(text(
                "ALTER TABLE hospitals ADD COLUMN rejection_reason TEXT"
            ))
        else:
            print("  rejection_reason already exists")

        if not column_exists(conn, "hospitals", "created_by"):
            print("  ADD created_by (INT FK -> users.id)")
            conn.execute(text(
                "ALTER TABLE hospitals ADD COLUMN created_by INTEGER "
                "REFERENCES users(id) ON DELETE SET NULL"
            ))
        else:
            print("  created_by already exists")

        if not column_exists(conn, "hospitals", "approved_by"):
            print("  ADD approved_by (INT FK -> users.id)")
            conn.execute(text(
                "ALTER TABLE hospitals ADD COLUMN approved_by INTEGER "
                "REFERENCES users(id) ON DELETE SET NULL"
            ))
        else:
            print("  approved_by already exists")

        if not column_exists(conn, "hospitals", "approved_at"):
            print("  ADD approved_at (TIMESTAMPTZ)")
            conn.execute(text(
                "ALTER TABLE hospitals ADD COLUMN approved_at TIMESTAMPTZ"
            ))
        else:
            print("  approved_at already exists")

        # ── 4. wards table additions ──────────────────────────────
        print("\n--- Updating wards table ---")

        if not column_exists(conn, "wards", "floor"):
            print("  ADD floor (INTEGER)")
            conn.execute(text("ALTER TABLE wards ADD COLUMN floor INTEGER"))
        else:
            print("  floor already exists")

        if not column_exists(conn, "wards", "capacity"):
            print("  ADD capacity (INTEGER)")
            conn.execute(text("ALTER TABLE wards ADD COLUMN capacity INTEGER"))
        else:
            print("  capacity already exists")

        if not column_exists(conn, "wards", "ward_status"):
            print("  ADD ward_status (wardstatus) DEFAULT 'ACTIVE'")
            conn.execute(text(
                "ALTER TABLE wards ADD COLUMN ward_status wardstatus "
                "NOT NULL DEFAULT 'ACTIVE'"
            ))
        else:
            print("  ward_status already exists")

        # ── 5. beds table additions ───────────────────────────────
        print("\n--- Updating beds table ---")

        if not column_exists(conn, "beds", "bed_type"):
            print("  ADD bed_type (bedtype) DEFAULT 'GENERAL'")
            conn.execute(text(
                "ALTER TABLE beds ADD COLUMN bed_type bedtype "
                "NOT NULL DEFAULT 'GENERAL'"
            ))
        else:
            print("  bed_type already exists")

        if not column_exists(conn, "beds", "patient_reference"):
            print("  ADD patient_reference (VARCHAR 150)")
            conn.execute(text(
                "ALTER TABLE beds ADD COLUMN patient_reference VARCHAR(150)"
            ))
        else:
            print("  patient_reference already exists")

    print("\n" + "=" * 60)
    print("  Migration complete — all columns verified.")
    print("=" * 60)


if __name__ == "__main__":
    run_migration()
