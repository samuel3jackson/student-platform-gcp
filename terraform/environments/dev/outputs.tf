output "vpc_id" {
  description = "VPC ID"
  value       = module.networking.vpc_id
}

output "vpc_name" {
  description = "VPC name"
  value       = module.networking.vpc_name
}

output "db_connection_name" {
  description = "Database connection name"
  value       = module.database.connection_name
}

output "backend_url" {
  description = "Backend API URL"
  value       = module.backend.service_url
}

output "frontend_url" {
  description = "Frontend URL"
  value       = module.frontend.website_url
}