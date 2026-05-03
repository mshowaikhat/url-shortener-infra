resource "google_secret_manager_secret" "this" {
  for_each = var.secrets

  project   = var.project_id
  secret_id = each.key

  replication {
    auto {}
  }
}

# Build a flat list of (secret_id, sa_email) pairs for IAM bindings
locals {
  secret_accessor_pairs = flatten([
    for secret_id, cfg in var.secrets : [
      for sa_email in cfg.accessor_sa_emails : {
        secret_id = secret_id
        sa_email  = sa_email
      }
    ]
  ])
}

resource "google_secret_manager_secret_iam_member" "accessor" {
  for_each = {
    for pair in local.secret_accessor_pairs :
    "${pair.secret_id}--${pair.sa_email}" => pair
  }

  project   = var.project_id
  secret_id = google_secret_manager_secret.this[each.value.secret_id].secret_id
  role      = "roles/secretmanager.secretAccessor"
  member    = "serviceAccount:${each.value.sa_email}"
}