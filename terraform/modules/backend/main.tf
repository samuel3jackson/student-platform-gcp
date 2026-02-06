# Service Account for Cloud Run
resource "google_service_account" "backend" {
  account_id   = "student-backend-${var.environment}"
  display_name = "Student Platform Backend"
  project      = var.project_id
}

# Grant Cloud SQL Client role to service account
resource "google_project_iam_member" "sql_client" {
  project = var.project_id
  role    = "roles/cloudsql.client"
  member  = "serviceAccount:${google_service_account.backend.email}"
}

# Cloud Run service
resource "google_cloud_run_v2_service" "backend" {
  name     = "student-platform-api-${var.environment}"
  location = var.region
  project  = var.project_id

  template {
    service_account                  = google_service_account.backend.email
    max_instance_request_concurrency = 1

    scaling {
      min_instance_count = 0
      max_instance_count = 2
    }

    containers {
      image = "${var.region}-docker.pkg.dev/${var.project_id}/student-platform/api:v10"

      ports {
        container_port = 8080
      }

      env {
        name  = "DATABASE_NAME"
        value = var.db_name
      }

      env {
        name  = "DATABASE_USER"
        value = var.db_user
      }

      env {
        name  = "DATABASE_PASSWORD"
        value = var.db_password
      }

      env {
        name  = "DATABASE_HOST"
        value = "/cloudsql/${var.db_connection_name}"
      }

      env {
        name  = "ENVIRONMENT"
        value = var.environment
      }

      resources {
        cpu_idle = true
        limits = {
          cpu    = "0.25"
          memory = "512Mi"
        }
      }

      volume_mounts {
        name       = "cloudsql"
        mount_path = "/cloudsql"
      }
    }

    volumes {
      name = "cloudsql"
      cloud_sql_instance {
        instances = [var.db_connection_name]
      }
    }
  }

  depends_on = [google_project_iam_member.sql_client]
}

# Allow public access (unauthenticated)
resource "google_cloud_run_v2_service_iam_member" "public" {
  project  = var.project_id
  location = var.region
  name     = google_cloud_run_v2_service.backend.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}