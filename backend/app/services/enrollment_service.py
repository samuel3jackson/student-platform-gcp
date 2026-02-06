from sqlalchemy.orm import Session
from sqlalchemy import func
from typing import Tuple
from collections import deque
from app import models

MAX_CLASSES_PER_SEMESTER = 5

class EnrollmentService:
    def __init__(self, db: Session):
        self.db = db
    
    def validate_enrollment(self, student_id: int, class_id: int, semester: str) -> Tuple[bool, str]:
        # Check student exists
        student = self.db.query(models.Student).filter(models.Student.id == student_id).first()
        if not student:
            return False, "Student not found"
        
        # Check class exists
        class_ = self.db.query(models.Class).filter(models.Class.id == class_id).first()
        if not class_:
            return False, "Class not found"
        
        # Check 5 class limit
        current_count = self.db.query(func.count(models.Enrollment.id)).filter(
            models.Enrollment.student_id == student_id,
            models.Enrollment.semester == semester,
            models.Enrollment.status == models.EnrollmentStatus.ENROLLED
        ).scalar()
        
        if current_count >= MAX_CLASSES_PER_SEMESTER:
            return False, f"Student already enrolled in {MAX_CLASSES_PER_SEMESTER} classes this semester"
        
        # Check prerequisites
        prereq_valid, prereq_msg = self.check_prerequisites(student_id, class_id)
        if not prereq_valid:
            return False, prereq_msg
        
        # Check class capacity
        enrolled_count = self.db.query(func.count(models.Enrollment.id)).filter(
            models.Enrollment.class_id == class_id,
            models.Enrollment.status == models.EnrollmentStatus.ENROLLED
        ).scalar()
        
        if enrolled_count >= class_.max_students:
            return False, "Class is full"
        
        # Check not already enrolled
        existing = self.db.query(models.Enrollment).filter(
            models.Enrollment.student_id == student_id,
            models.Enrollment.class_id == class_id,
            models.Enrollment.semester == semester
        ).first()
        
        if existing:
            return False, "Already enrolled in this class"
        
        return True, "OK"
    
    def check_prerequisites(self, student_id: int, class_id: int) -> Tuple[bool, str]:
        prereqs = self.db.query(models.ClassPrerequisite).filter(
            models.ClassPrerequisite.class_id == class_id
        ).all()
        
        if not prereqs:
            return True, "No prerequisites"
        
        completed = self.db.query(models.Enrollment.class_id).filter(
            models.Enrollment.student_id == student_id,
            models.Enrollment.status == models.EnrollmentStatus.COMPLETED
        ).all()
        completed_ids = {c[0] for c in completed}
        
        missing = []
        for prereq in prereqs:
            if prereq.prerequisite_id not in completed_ids:
                prereq_class = self.db.query(models.Class).filter(
                    models.Class.id == prereq.prerequisite_id
                ).first()
                if prereq_class:
                    missing.append(prereq_class.name)
        
        if missing:
            return False, f"Missing prerequisites: {', '.join(missing)}"
        
        return True, "Prerequisites satisfied"
    
    def check_circular_prerequisites(self, class_id: int, prereq_id: int) -> bool:
        """Returns True if adding this prerequisite would create a cycle"""
        visited = set()
        queue = deque([prereq_id])
        
        while queue:
            current = queue.popleft()
            if current == class_id:
                return True
            if current in visited:
                continue
            visited.add(current)
            
            prereqs = self.db.query(models.ClassPrerequisite.prerequisite_id).filter(
                models.ClassPrerequisite.class_id == current
            ).all()
            queue.extend([p[0] for p in prereqs])
        
        return False
