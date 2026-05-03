resource "google_project_service" "this" {
  for_each = toset(var.apis)

  project = var.project_id
  service = each.value

  # Don't disable the API when this resource is destroyed; other resources
  # in the project may still depend on it. Avoids cascading destroy failures.
  disable_on_destroy = false
}