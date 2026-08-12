import os
import sys
# Add current directory to path if run from root
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from sqlalchemy import inspect
from app.database.session import engine, SessionLocal
from app.models import User

def test_connection():
    print("Testing connection to PostgreSQL...")
    try:
        # Check connection
        connection = engine.connect()
        print("Successfully connected to the database!")
        
        # Check tables using Inspector
        inspector = inspect(engine)
        tables = inspector.get_table_names()
        print(f"Tables in database: {tables}")
        
        # Test Query
        db = SessionLocal()
        try:
            user_count = db.query(User).count()
            print(f"Connection test complete. Number of registered users in DB: {user_count}")
            if user_count > 0:
                print("Seeded Users found:")
                for user in db.query(User).limit(5).all():
                    print(f" - {user.full_name} ({user.email}) -> Role: {user.role.value}")
        except Exception as q_err:
            print(f"Connection worked, but query failed (tables might not be initialized yet): {q_err}")
            print("Run python app/database/init_db.py to create and seed tables.")
        finally:
            db.close()
            
        connection.close()
    except Exception as e:
        print(f"Failed to connect to the database: {e}")
        print("Please check your DATABASE_URL in backend/.env")

if __name__ == "__main__":
    test_connection()
