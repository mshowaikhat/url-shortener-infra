output "repository_id" {
  description = "The repository ID"
  value       = google_artifact_registry_repository.services.repository_id
}

output "repository_url" {
  description = "Full registry URL prefix for pushing images"
  value       = "${var.region}-docker.pkg.dev/${var.project_id}/${google_artifact_registry_repository.services.repository_id}"
}