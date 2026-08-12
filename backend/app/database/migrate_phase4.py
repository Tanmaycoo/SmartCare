"""
Safe migration script to update existing PostgreSQL database schema for Phase 4.
Adds missing columns to `hospitals` table and creates necessary ENUM types
without dropping tables, truncating data, or breaking existing users.
"""

import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))))

from sqlalchemy import inspect, text
from app.database.session import engine

def migrate_hospitals_table():
    print("Beginning safe PostgreSQL schema migration for Phase 4...")
    
    with engine.begin() as conn:
        inspector = inspect(engine)
        existing_columns = [col['name'] for col in inspector.get_columns('hospitals')]
        print(f"Existing columns in 'hospitals' table: {existing_columns}")

        # 1. Ensure `verificationstatus` ENUM exists in PostgreSQL
        conn.execute(text("""
            DO $$
            BEGIN
                IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'verificationstatus') THEN
                    CREATE TYPE verificationstatus AS ENUM ('PENDING', 'VERIFIED', 'REJECTED', 'SUSPENDED');
                END IF;
            END$$;
        """))
        print("Ensured 'verificationstatus' ENUM type exists.")

        # 2. Ensure `hospitalstatus` ENUM has 'INACTIVE' value if needed
        conn.execute(text("""
            DO $$
            BEGIN
                IF EXISTS (SELECT 1 FROM pg_type WHERE typname = 'hospitalstatus') THEN
                    ALTER TYPE hospitalstatus ADD VALUE IF NOT EXISTS 'INACTIVE';
                    ALTER TYPE hospitalstatus ADD VALUE IF NOT EXISTS 'ACTIVE';
                ELSE
                    CREATE TYPE hospitalstatus AS ENUM ('ACTIVE', 'INACTIVE');
                END IF;
            END$$;
        """))
        print("Ensured 'hospitalstatus' ENUM type has ACTIVE and INACTIVE.")

        # 3. Safely add missing columns to `hospitals` table
        
        # city
        if 'city' not in existing_columns:
            print("Adding column 'city'...")
            conn.execute(text("ALTER TABLE hospitals ADD COLUMN city VARCHAR(100) NOT NULL DEFAULT '';"))

        # state
        if 'state' not in existing_columns:
            print("Adding column 'state'...")
            conn.execute(text("ALTER TABLE hospitals ADD COLUMN state VARCHAR(100) NOT NULL DEFAULT '';"))

        # postal_code
        if 'postal_code' not in existing_columns:
            print("Adding column 'postal_code'...")
            conn.execute(text("ALTER TABLE hospitals ADD COLUMN postal_code VARCHAR(20) NOT NULL DEFAULT '';"))

        # emergency_available
        if 'emergency_available' not in existing_columns:
            print("Adding column 'emergency_available'...")
            conn.execute(text("ALTER TABLE hospitals ADD COLUMN emergency_available BOOLEAN NOT NULL DEFAULT TRUE;"))

        # verification_status
        if 'verification_status' not in existing_columns:
            print("Adding column 'verification_status'...")
            conn.execute(text("""
                ALTER TABLE hospitals 
                ADD COLUMN verification_status verificationstatus NOT NULL DEFAULT 'PENDING';
            """))
            # Populate verification_status from old status column if present
            conn.execute(text("""
                UPDATE hospitals 
                SET verification_status = CASE 
                    WHEN status::text = 'VERIFIED' THEN 'VERIFIED'::verificationstatus
                    WHEN status::text = 'SUSPENDED' THEN 'SUSPENDED'::verificationstatus
                    ELSE 'PENDING'::verificationstatus
                END
                WHERE verification_status = 'PENDING';
            """))

        # admin_id
        if 'admin_id' not in existing_columns:
            print("Adding column 'admin_id' with foreign key to users(id)...")
            conn.execute(text("""
                ALTER TABLE hospitals 
                ADD COLUMN admin_id INTEGER NULL REFERENCES users(id) ON DELETE SET NULL;
            """))

        # 4. Migrate old hospital status values to new ACTIVE/INACTIVE status if necessary
        # If status column exists, make sure default is INACTIVE and values are valid
        conn.execute(text("""
            UPDATE hospitals
            SET status = 'ACTIVE'::hospitalstatus
            WHERE status::text IN ('ACTIVE', 'VERIFIED');
        """))

    print("\nMigration completed successfully!")
    print("Updated columns in 'hospitals' table:")
    with engine.connect() as conn:
        inspector = inspect(engine)
        updated_columns = [col['name'] for col in inspector.get_columns('hospitals')]
        print(updated_columns)

if __name__ == "__main__":
    migrate_hospitals_table()
