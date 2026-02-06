import os
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from google.cloud.sql.connector import Connector, IPTypes

def get_connection():
    db_user = os.getenv("DATABASE_USER", "app_user")
    db_pass = os.getenv("DATABASE_PASSWORD", "")
    db_name = os.getenv("DATABASE_NAME", "student_platform")
    db_host = os.getenv("DATABASE_HOST", "")
    
    # Local development
    if not db_host.startswith("/cloudsql/"):
        db_host = db_host or "localhost"
        db_port = os.getenv("DATABASE_PORT", "5432")
        url = f"postgresql+pg8000://{db_user}:{db_pass}@{db_host}:{db_port}/{db_name}"
        return create_engine(url)
    
    # Cloud SQL - use connector with public IP
    connection_name = db_host.replace("/cloudsql/", "")
    
    connector = Connector()
    
    def getconn():
        return connector.connect(
            connection_name,
            "pg8000",
            user=db_user,
            password=db_pass,
            db=db_name,
            ip_type=IPTypes.PUBLIC,
        )
    
    return create_engine("postgresql+pg8000://", creator=getconn)

engine = get_connection()
SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()