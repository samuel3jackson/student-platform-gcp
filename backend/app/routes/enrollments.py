from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import List
from app.database import get_db
from app import models, schemas
from app.services.enrollment_service import EnrollmentService

router = APIRouter()

@router.get("/", response_model=List[schemas.Enrollment])
def list_enrollments(student_id: int = None, class_id: int = None, db: Session = Depends(get_db)):
    query = db.query(models.Enrollment)
    if student_id:
        query = query.filter(models.Enrollment.student_id == student_id)
    if class_id:
        query = query.filter(models.Enrollment.class_id == class_id)
    return query.all()

@router.post("/", response_model=schemas.Enrollment)
def create_enrollment(enrollment: schemas.EnrollmentCreate, db: Session = Depends(get_db)):
    service = EnrollmentService(db)
    valid, message = service.validate_enrollment(
        enrollment.student_id, 
        enrollment.class_id, 
        enrollment.semester
    )
    
    if not valid:
        raise HTTPException(status_code=400, detail=message)
    
    db_enrollment = models.Enrollment(**enrollment.model_dump())
    db.add(db_enrollment)
    db.commit()
    db.refresh(db_enrollment)
    return db_enrollment

@router.get("/student/{student_id}/semester/{semester}/count")
def get_enrollment_count(student_id: int, semester: str, db: Session = Depends(get_db)):
    count = db.query(func.count(models.Enrollment.id)).filter(
        models.Enrollment.student_id == student_id,
        models.Enrollment.semester == semester,
        models.Enrollment.status == models.EnrollmentStatus.ENROLLED
    ).scalar()
    return {"student_id": student_id, "semester": semester, "count": count, "max": 5}

@router.patch("/{enrollment_id}/complete")
def complete_enrollment(enrollment_id: int, grade: str, db: Session = Depends(get_db)):
    enrollment = db.query(models.Enrollment).filter(models.Enrollment.id == enrollment_id).first()
    if not enrollment:
        raise HTTPException(status_code=404, detail="Enrollment not found")
    
    enrollment.status = models.EnrollmentStatus.COMPLETED
    enrollment.grade = grade
    db.commit()
    db.refresh(enrollment)
    return enrollment
