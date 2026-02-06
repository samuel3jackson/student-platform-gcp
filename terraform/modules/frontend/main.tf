resource "google_storage_bucket" "frontend" {
  name          = "${var.project_id}-frontend-${var.environment}"
  project       = var.project_id
  location      = var.region
  force_destroy = true

  website {
    main_page_suffix = "index.html"
    not_found_page   = "index.html"
  }

  cors {
    origin          = ["*"]
    method          = ["GET", "HEAD", "OPTIONS"]
    response_header = ["*"]
    max_age_seconds = 3600
  }
}

resource "google_storage_bucket_iam_member" "public_read" {
  bucket = google_storage_bucket.frontend.name
  role   = "roles/storage.objectViewer"
  member = "allUsers"
}

resource "google_storage_bucket_object" "index" {
  name         = "index.html"
  bucket       = google_storage_bucket.frontend.name
  content_type = "text/html"
  content      = <<-EOT
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Student Platform</title>
    <style>
        * { box-sizing: border-box; margin: 0; padding: 0; }
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; background: #f5f5f5; padding: 20px; }
        .container { max-width: 1200px; margin: 0 auto; }
        h1 { color: #333; margin-bottom: 20px; }
        .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(350px, 1fr)); gap: 20px; }
        .card { background: white; border-radius: 8px; padding: 20px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .card h3 { margin-bottom: 15px; color: #2563eb; }
        input, select, button { padding: 10px; border: 1px solid #ddd; border-radius: 4px; font-size: 14px; }
        input, select { width: 100%; margin-bottom: 10px; }
        button { background: #2563eb; color: white; border: none; cursor: pointer; width: 100%; }
        button:hover { background: #1d4ed8; }
        .list { margin-top: 15px; max-height: 300px; overflow-y: auto; }
        .list-item { padding: 10px; border-bottom: 1px solid #eee; }
        .badge { display: inline-block; padding: 2px 8px; border-radius: 12px; font-size: 12px; margin-left: 8px; }
        .badge.enrolled { background: #dbeafe; color: #1d4ed8; }
        .badge.completed { background: #d1fae5; color: #059669; }
        .error { color: #dc2626; margin-top: 10px; padding: 10px; background: #fef2f2; border-radius: 4px; }
        .success { color: #059669; margin-top: 10px; padding: 10px; background: #f0fdf4; border-radius: 4px; }
        .stats { display: flex; gap: 20px; margin-bottom: 20px; flex-wrap: wrap; }
        .stat { background: white; padding: 15px 25px; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.1); }
        .stat-value { font-size: 24px; font-weight: bold; color: #2563eb; }
        .stat-label { font-size: 12px; color: #6b7280; }
    </style>
</head>
<body>
    <div class="container">
        <h1>Student Platform</h1>
        <p style="margin-bottom: 20px; color: #666;">Business Rules: 5-class limit per semester | Prerequisites | Class capacity</p>
        
        <div class="stats">
            <div class="stat"><div class="stat-value" id="student-count">-</div><div class="stat-label">Students</div></div>
            <div class="stat"><div class="stat-value" id="class-count">-</div><div class="stat-label">Classes</div></div>
            <div class="stat"><div class="stat-value" id="enrollment-count">-</div><div class="stat-label">Enrollments</div></div>
        </div>

        <div class="grid">
            <div class="card">
                <h3>Students</h3>
                <input type="text" id="student-name" placeholder="Name">
                <input type="email" id="student-email" placeholder="Email">
                <input type="text" id="student-id" placeholder="Student ID (e.g., STU003)">
                <button onclick="createStudent()">Add Student</button>
                <div class="list" id="student-list"></div>
            </div>

            <div class="card">
                <h3>Classes</h3>
                <input type="text" id="class-name" placeholder="Class Name">
                <input type="text" id="class-code" placeholder="Code (e.g., CS101)">
                <input type="text" id="class-semester" placeholder="Semester" value="Fall2024">
                <button onclick="createClass()">Add Class</button>
                <div class="list" id="class-list"></div>
            </div>

            <div class="card">
                <h3>Enroll Student</h3>
                <select id="enroll-student"></select>
                <select id="enroll-class"></select>
                <input type="text" id="enroll-semester" value="Fall2024">
                <button onclick="createEnrollment()">Enroll</button>
                <div id="enroll-message"></div>
                <div class="list" id="enrollment-list" style="margin-top:15px;"></div>
            </div>

            <div class="card">
                <h3>Check Enrollment Count</h3>
                <select id="count-student"></select>
                <input type="text" id="count-semester" value="Fall2024">
                <button onclick="checkCount()">Check Count</button>
                <div id="count-result"></div>
                
                <h3 style="margin-top:20px;">Complete Enrollment</h3>
                <input type="number" id="complete-id" placeholder="Enrollment ID">
                <input type="text" id="complete-grade" placeholder="Grade (A, B, C...)">
                <button onclick="completeEnrollment()">Mark Complete</button>
                <div id="complete-message"></div>
            </div>
        </div>
    </div>

    <script>
        const API = '${var.api_url}/api/v1';

        async function api(endpoint, method = 'GET', data = null) {
            const opts = { method, headers: { 'Content-Type': 'application/json' } };
            if (data) opts.body = JSON.stringify(data);
            const res = await fetch(API + endpoint, opts);
            return res.json();
        }

        async function loadStudents() {
            const students = await api('/students/');
            document.getElementById('student-count').textContent = students.length;
            document.getElementById('student-list').innerHTML = students.map(s => 
                '<div class="list-item"><strong>' + s.name + '</strong><br><small>' + s.email + ' - ' + s.student_id + '</small></div>'
            ).join('');
            const opts = students.map(s => '<option value="' + s.id + '">' + s.name + '</option>').join('');
            document.getElementById('enroll-student').innerHTML = opts;
            document.getElementById('count-student').innerHTML = opts;
        }

        async function loadClasses() {
            const classes = await api('/classes/');
            document.getElementById('class-count').textContent = classes.length;
            document.getElementById('class-list').innerHTML = classes.map(c => 
                '<div class="list-item"><strong>' + c.name + '</strong><br><small>' + c.code + ' - ' + c.semester + '</small></div>'
            ).join('');
            document.getElementById('enroll-class').innerHTML = classes.map(c => 
                '<option value="' + c.id + '">' + c.code + ': ' + c.name + '</option>'
            ).join('');
        }

        async function loadEnrollments() {
            const enrollments = await api('/enrollments/');
            document.getElementById('enrollment-count').textContent = enrollments.length;
            document.getElementById('enrollment-list').innerHTML = enrollments.map(e => 
                '<div class="list-item">ID ' + e.id + ': Student ' + e.student_id + ' to Class ' + e.class_id + ' <span class="badge ' + e.status + '">' + e.status + (e.grade ? ' (' + e.grade + ')' : '') + '</span></div>'
            ).join('');
        }

        async function createStudent() {
            await api('/students/', 'POST', {
                name: document.getElementById('student-name').value,
                email: document.getElementById('student-email').value,
                student_id: document.getElementById('student-id').value,
                grade_level: 10
            });
            loadStudents();
        }

        async function createClass() {
            await api('/classes/', 'POST', {
                name: document.getElementById('class-name').value,
                code: document.getElementById('class-code').value,
                semester: document.getElementById('class-semester').value,
                max_students: 30
            });
            loadClasses();
        }

        async function createEnrollment() {
            const result = await api('/enrollments/', 'POST', {
                student_id: parseInt(document.getElementById('enroll-student').value),
                class_id: parseInt(document.getElementById('enroll-class').value),
                semester: document.getElementById('enroll-semester').value
            });
            const msg = document.getElementById('enroll-message');
            if (result.detail) {
                msg.className = 'error';
                msg.textContent = 'Error: ' + result.detail;
            } else {
                msg.className = 'success';
                msg.textContent = 'Enrolled successfully!';
                loadEnrollments();
            }
        }

        async function checkCount() {
            const result = await api('/enrollments/student/' + document.getElementById('count-student').value + '/semester/' + document.getElementById('count-semester').value + '/count');
            document.getElementById('count-result').innerHTML = '<div class="success">' + result.count + ' of ' + result.max + ' classes</div>';
        }

        async function completeEnrollment() {
            const result = await api('/enrollments/' + document.getElementById('complete-id').value + '/complete?grade=' + document.getElementById('complete-grade').value, 'PATCH');
            const msg = document.getElementById('complete-message');
            if (result.detail) { msg.className = 'error'; msg.textContent = 'Error: ' + result.detail; }
            else { msg.className = 'success'; msg.textContent = 'Completed!'; loadEnrollments(); }
        }

        loadStudents(); loadClasses(); loadEnrollments();
    </script>
</body>
</html>
EOT
}