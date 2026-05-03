output "enabled_apis" {
  description = "Map of API name to the google_project_service resource"
  value       = google_project_service.this
}