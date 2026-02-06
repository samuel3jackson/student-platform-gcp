from pydantic import BaseModel, EmailStr
from typing import Optional, List
from enum import Enum

class EnrollmentStatus(str, Enum):
    ENROLLED = "enrolled"
    COMPLETED = "completed"
    DROPPED = "dropped"

# Teacher schemas
class TeacherBase(BaseModel):
    name: str
    email: EmailStr
    department: Optional[str] = None

class TeacherCreate(TeacherBase):
    pass

class Teacher(TeacherBase):
    id: int
    class Config:
        from_attributes = True

# Student schemas
class StudentBase(BaseModel):
    name: str
    email: EmailStr
    student_id: str
    grade_level: Optional[int] = None

class StudentCreate(StudentBase):
    pass

class Student(StudentBase):
    id: int
    class Config:
        from_attributes = True

# Class schemas
class ClassBase(BaseModel):
    name: str
    code: str
    semester: str
    max_students: Optional[int] = 30
    teacher_id: Optional[int] = None

class ClassCreate(ClassBase):
    pass

class Class(ClassBase):
    id: int
    class Config:
        from_attributes = True

class ClassWithPrereqs(Class):
    prerequisites: List[Class] = []

# Enrollment schemas
class EnrollmentBase(BaseModel):
    student_id: int
    class_id: int
    semester: str

class EnrollmentCreate(EnrollmentBase):
    pass

class Enrollment(EnrollmentBase):
    id: int
    status: EnrollmentStatus
    grade: Optional[str] = None
    class Config:
        from_attributes = True

# Prerequisite schema
class PrerequisiteCreate(BaseModel):
    prerequisite_id: int
