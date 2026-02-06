resource "google_sql_database_instance" "main" {
  name             = "student-platform-db-${var.environment}"
  project          = var.project_id
  region           = var.region
  database_version = "POSTGRES_15"

  deletion_protection = false

  settings {
    tier              = "db-f1-micro"
    availability_type = "ZONAL"
    disk_size         = 10
    disk_type         = "PD_SSD"

    ip_configuration {
      ipv4_enabled = true
      require_ssl  = true

      authorized_networks {
        name  = "allow-all"  # Prod: restrict to Cloud Run egress IPs
        value = "0.0.0.0/0"
      }
    }

    backup_configuration {
      enabled    = true
      start_time = "03:00"
    }
  }

  depends_on = [var.private_vpc_connection]
}

resource "google_sql_database" "main" {
  name     = "student_platform"
  project  = var.project_id
  instance = google_sql_database_instance.main.name
}

resource "google_sql_user" "app" {
  name     = "app_user"
  project  = var.project_id
  instance = google_sql_database_instance.main.name
  password = var.db_password
}