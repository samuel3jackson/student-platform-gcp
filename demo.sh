# === DEMO COMMANDS ===

# 1. Health check
curl https://student-platform-api-dev-73rpnkg6jq-uc.a.run.app/

# 2. List all students
curl https://student-platform-api-dev-73rpnkg6jq-uc.a.run.app/api/v1/students/

# 3. List all classes
curl https://student-platform-api-dev-73rpnkg6jq-uc.a.run.app/api/v1/classes/

# 4. Check enrollment count (shows 5/5 for John)
curl https://student-platform-api-dev-73rpnkg6jq-uc.a.run.app/api/v1/enrollments/student/1/semester/Fall2024/count

# 5. TRY 6TH ENROLLMENT - FAILS (5-class limit)
curl -X POST https://student-platform-api-dev-73rpnkg6jq-uc.a.run.app/api/v1/enrollments/ \
  -H "Content-Type: application/json" \
  -d '{"student_id": 1, "class_id": 6, "semester": "Fall2024"}'
# → "Student already enrolled in 5 classes this semester"

# 6. Create new student
curl -X POST https://student-platform-api-dev-73rpnkg6jq-uc.a.run.app/api/v1/students/ \
  -H "Content-Type: application/json" \
  -d '{"name": "Demo Student", "email": "demo@test.edu", "student_id": "STU999", "grade_level": 10}'

# 7. TRY ENROLL IN CS201 WITHOUT PREREQ - FAILS
curl -X POST https://student-platform-api-dev-73rpnkg6jq-uc.a.run.app/api/v1/enrollments/ \
  -H "Content-Type: application/json" \
  -d '{"student_id": 3, "class_id": 2, "semester": "Fall2024"}'
# → "Missing prerequisites: Intro to CS"

# 8. Enroll in CS101 first (the prerequisite)
curl -X POST https://student-platform-api-dev-73rpnkg6jq-uc.a.run.app/api/v1/enrollments/ \
  -H "Content-Type: application/json" \
  -d '{"student_id": 3, "class_id": 1, "semester": "Fall2024"}'

# 9. Complete CS101 with grade A
curl -X PATCH "https://student-platform-api-dev-73rpnkg6jq-uc.a.run.app/api/v1/enrollments/8/complete?grade=A"

# 10. NOW enroll in CS201 - SUCCEEDS
curl -X POST https://student-platform-api-dev-73rpnkg6jq-uc.a.run.app/api/v1/enrollments/ \
  -H "Content-Type: application/json" \
  -d '{"student_id": 3, "class_id": 2, "semester": "Fall2024"}'

# 11. List all enrollments
curl https://student-platform-api-dev-73rpnkg6jq-uc.a.run.app/api/v1/enrollments/
