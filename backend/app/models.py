from sqlalchemy import Column, Integer, String, ForeignKey, Enum, UniqueConstraint
from sqlalchemy.orm import relationship, declarative_base
import enum

Base = declarative_base()

class EnrollmentStatus(enum.Enum):
    ENROLLED = "enrolled"
    COMPLETED = "completed"
    DROPPED = "dropped"

class Teacher(Base):
    __tablename__ = "teachers"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    email = Column(String(100), unique=True, nullable=False)
    department = Column(String(100))
    
    classes = relationship("Class", back_populates="teacher")

class Student(Base):
    __tablename__ = "students"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    email = Column(String(100), unique=True, nullable=False)
    student_id = Column(String(20), unique=True, nullable=False)
    grade_level = Column(Integer)
    
    enrollments = relationship("Enrollment", back_populates="student")

class Class(Base):
    __tablename__ = "classes"
    
    id = Column(Integer, primary_key=True, index=True)
    name = Column(String(100), nullable=False)
    code = Column(String(20), nullable=False)
    semester = Column(String(20), nullable=False)
    max_students = Column(Integer, default=30)
    teacher_id = Column(Integer, ForeignKey("teachers.id"))
    
    teacher = relationship("Teacher", back_populates="classes")
    enrollments = relationship("Enrollment", back_populates="class_")
    prerequisites = relationship(
        "Class",
        secondary="class_prerequisites",
        primaryjoin="Class.id==ClassPrerequisite.class_id",
        secondaryjoin="Class.id==ClassPrerequisite.prerequisite_id",
        backref="required_for"
    )
    
    __table_args__ = (
        UniqueConstraint('code', 'semester', name='unique_class_semester'),
    )

class ClassPrerequisite(Base):
    __tablename__ = "class_prerequisites"
    
    class_id = Column(Integer, ForeignKey("classes.id"), primary_key=True)
    prerequisite_id = Column(Integer, ForeignKey("classes.id"), primary_key=True)

class Enrollment(Base):
    __tablename__ = "enrollments"
    
    id = Column(Integer, primary_key=True, index=True)
    student_id = Column(Integer, ForeignKey("students.id"), nullable=False)
    class_id = Column(Integer, ForeignKey("classes.id"), nullable=False)
    semester = Column(String(20), nullable=False)
    status = Column(Enum(EnrollmentStatus), default=EnrollmentStatus.ENROLLED)
    grade = Column(String(2))
    
    student = relationship("Student", back_populates="enrollments")
    class_ = relationship("Class", back_populates="enrollments")
    
    __table_args__ = (
        UniqueConstraint('student_id', 'class_id', 'semester', name='unique_enrollment'),
    )
