# Firestore in Native mode. ONE database per project (the (default) database).
# This resource is essentially permanent — once created, it cannot be moved.
resource "google_firestore_database" "default" {
  project     = var.project_id
  name        = "(default)"
  location_id = var.location_id
  type        = "FIRESTORE_NATIVE"

  # Don't let `terraform destroy` delete the database. We'd lose all data
  # AND would have to wait days before we could re-enable Firestore.
  deletion_policy = "ABANDON"

  lifecycle {
    prevent_destroy = true
  }
}