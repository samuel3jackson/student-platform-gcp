output "vpc_id" {
  description = "VPC ID"
  value       = google_compute_network.main.id
}

output "vpc_name" {
  description = "VPC name"
  value       = google_compute_network.main.name
}

output "subnet_id" {
  description = "Subnet ID"
  value       = google_compute_subnetwork.main.id
}

output "private_vpc_connection" {
  description = "Private VPC connection ID"
  value       = google_service_networking_connection.private_vpc.id
}