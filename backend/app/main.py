from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager

@asynccontextmanager
async def lifespan(app: FastAPI):
    yield

app = FastAPI(
    title="Student Platform API",
    description="API for managing students, classes, and enrollments",
    version="1.0.0",
    lifespan=lifespan
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# Import routes after app is created
from app.routes import teachers, students, classes, enrollments

app.include_router(teachers.router, prefix="/api/v1/teachers", tags=["Teachers"])
app.include_router(students.router, prefix="/api/v1/students", tags=["Students"])
app.include_router(classes.router, prefix="/api/v1/classes", tags=["Classes"])
app.include_router(enrollments.router, prefix="/api/v1/enrollments", tags=["Enrollments"])

@app.get("/")
def root():
    return {"message": "Student Platform API", "version": "1.0.0"}

@app.get("/health")
def health():
    return {"status": "healthy"}

@app.post("/migrate")
def migrate():
    """Create database tables"""
    try:
        from app.database import engine
        from app.models import Base
        Base.metadata.create_all(bind=engine)
        return {"status": "success", "message": "Tables created"}
    except Exception as e:
        return {"status": "error", "message": str(e)}