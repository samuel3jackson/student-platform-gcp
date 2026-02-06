output "bucket_name" {
  description = "Frontend bucket name"
  value       = google_storage_bucket.frontend.name
}

output "website_url" {
  description = "Frontend website URL"
  value       = "https://storage.googleapis.com/${google_storage_bucket.frontend.name}/index.html"
}
