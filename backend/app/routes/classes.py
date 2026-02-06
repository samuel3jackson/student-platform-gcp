from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List
from app.database import get_db
from app import models, schemas
from app.services.enrollment_service import EnrollmentService

router = APIRouter()

@router.get("/", response_model=List[schemas.Class])
def list_classes(semester: str = None, db: Session = Depends(get_db)):
    query = db.query(models.Class)
    if semester:
        query = query.filter(models.Class.semester == semester)
    return query.all()

@router.post("/", response_model=schemas.Class)
def create_class(class_: schemas.ClassCreate, db: Session = Depends(get_db)):
    db_class = models.Class(**class_.model_dump())
    db.add(db_class)
    db.commit()
    db.refresh(db_class)
    return db_class

@router.get("/{class_id}", response_model=schemas.ClassWithPrereqs)
def get_class(class_id: int, db: Session = Depends(get_db)):
    class_ = db.query(models.Class).filter(models.Class.id == class_id).first()
    if not class_:
        raise HTTPException(status_code=404, detail="Class not found")
    return class_

@router.post("/{class_id}/prerequisites")
def add_prerequisite(class_id: int, prereq: schemas.PrerequisiteCreate, db: Session = Depends(get_db)):
    class_ = db.query(models.Class).filter(models.Class.id == class_id).first()
    if not class_:
        raise HTTPException(status_code=404, detail="Class not found")
    
    prereq_class = db.query(models.Class).filter(models.Class.id == prereq.prerequisite_id).first()
    if not prereq_class:
        raise HTTPException(status_code=404, detail="Prerequisite class not found")
    
    service = EnrollmentService(db)
    if service.check_circular_prerequisites(class_id, prereq.prerequisite_id):
        raise HTTPException(status_code=400, detail="Would create circular prerequisite")
    
    db_prereq = models.ClassPrerequisite(class_id=class_id, prerequisite_id=prereq.prerequisite_id)
    db.add(db_prereq)
    db.commit()
    
    return {"message": "Prerequisite added"}
