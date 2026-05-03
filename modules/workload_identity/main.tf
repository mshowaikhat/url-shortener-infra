data "google_project" "this" {
  project_id = var.project_id
}

# ----- Workload Identity Pool -----

resource "google_iam_workload_identity_pool" "github" {
  project                   = var.project_id
  workload_identity_pool_id = var.pool_id
  display_name              = "GitHub Actions"
  description               = "Pool for GitHub Actions OIDC federation"
}

# ----- OIDC Provider for GitHub -----

resource "google_iam_workload_identity_pool_provider" "github" {
  project                            = var.project_id
  workload_identity_pool_id          = google_iam_workload_identity_pool.github.workload_identity_pool_id
  workload_identity_pool_provider_id = var.provider_id
  display_name                       = "GitHub OIDC"

  # Map GitHub OIDC token claims to attributes we can match against in IAM bindings
  attribute_mapping = {
    "google.subject"       = "assertion.sub"
    "attribute.repository" = "assertion.repository"
    "attribute.actor"      = "assertion.actor"
    "attribute.ref"        = "assertion.ref"
  }

  # SECURITY: Only allow tokens whose 'repository_owner' matches our GitHub owner.
  # Without this, any GitHub user could attempt to authenticate.
  attribute_condition = "assertion.repository_owner == '${var.github_owner}'"

  oidc {
    issuer_uri = "https://token.actions.githubusercontent.com"
  }
}

# ----- Bindings: each repo can impersonate its assigned SA -----

resource "google_service_account_iam_member" "wif_binding" {
  for_each = var.repo_to_sa_bindings

  service_account_id = "projects/${var.project_id}/serviceAccounts/${each.value.sa_email}"
  role               = "roles/iam.workloadIdentityUser"
  member             = "principalSet://iam.googleapis.com/projects/${data.google_project.this.number}/locations/global/workloadIdentityPools/${google_iam_workload_identity_pool.github.workload_identity_pool_id}/attribute.repository/${var.github_owner}/${each.value.repo_name}"
}