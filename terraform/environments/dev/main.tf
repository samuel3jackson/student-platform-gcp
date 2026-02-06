# Enable required APIs
resource "google_project_service" "compute" {
  project            = var.project_id
  service            = "compute.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "sqladmin" {
  project            = var.project_id
  service            = "sqladmin.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "servicenetworking" {
  project            = var.project_id
  service            = "servicenetworking.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "run" {
  project            = var.project_id
  service            = "run.googleapis.com"
  disable_on_destroy = false
}

resource "google_project_service" "artifactregistry" {
  project            = var.project_id
  service            = "artifactregistry.googleapis.com"
  disable_on_destroy = false
}

# Artifact Registry for container images
resource "google_artifact_registry_repository" "backend" {
  location      = var.region
  repository_id = "student-platform"
  description   = "Docker repository for student platform"
  format        = "DOCKER"
  project       = var.project_id

  depends_on = [google_project_service.artifactregistry]
}

# Networking
module "networking" {
  source = "../../modules/networking"

  project_id  = var.project_id
  region      = var.region
  environment = var.environment

  depends_on = [
    google_project_service.compute,
    google_project_service.servicenetworking
  ]
}

# Database
module "database" {
  source = "../../modules/database"

  project_id             = var.project_id
  region                 = var.region
  environment            = var.environment
  vpc_id                 = module.networking.vpc_id
  db_password            = var.db_password
  private_vpc_connection = module.networking.private_vpc_connection

  depends_on = [google_project_service.sqladmin]
}

# Backend (Cloud Run)
module "backend" {
  source = "../../modules/backend"

  project_id         = var.project_id
  region             = var.region
  environment        = var.environment
  db_connection_name = module.database.connection_name
  db_name            = module.database.database_name
  db_user            = module.database.database_user
  db_password        = var.db_password

  depends_on = [google_project_service.run, module.database]
}

# Frontend (Cloud Storage)
module "frontend" {
  source = "../../modules/frontend"

  project_id  = var.project_id
  region      = var.region
  environment = var.environment
  api_url     = module.backend.service_url

  depends_on = [module.backend]
}