resource "google_artifact_registry_repository" "services" {
  project       = var.project_id
  location      = var.region
  repository_id = var.repository_id
  description   = "Container images for SWE 455 URL shortener services"
  format        = "DOCKER"

  docker_config {
    immutable_tags = false
  }
}