# ----- Service accounts -----

resource "google_service_account" "shortener" {
  project      = var.project_id
  account_id   = "shortener-sa"
  display_name = "Shortener Service Cloud Run SA"
}

resource "google_service_account" "redirect" {
  project      = var.project_id
  account_id   = "redirect-sa"
  display_name = "Redirect Service Cloud Run SA"
}

resource "google_service_account" "infra_deployer" {
  project      = var.project_id
  account_id   = "infra-deployer-sa"
  display_name = "Infra Repo Terraform Deployer (used by GitHub Actions via WIF)"
}

# ----- Roles for shortener-sa -----

locals {
  service_runtime_roles = [
    "roles/datastore.user",                # Firestore read/write
    "roles/secretmanager.secretAccessor",  # Read secrets at runtime
    "roles/logging.logWriter",             # stdout -> Cloud Logging
    "roles/monitoring.metricWriter",       # Custom metrics
    "roles/cloudtrace.agent"               # Send spans to Cloud Trace
  ]
}

resource "google_project_iam_member" "shortener_roles" {
  for_each = toset(local.service_runtime_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.shortener.email}"
}

# ----- Roles for redirect-sa -----

resource "google_project_iam_member" "redirect_roles" {
  for_each = toset(local.service_runtime_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.redirect.email}"
}

# ----- Roles for infra-deployer-sa -----
# This SA will be impersonated by GitHub Actions via WIF in Slice 4.
# It needs to manage all the resources Terraform creates.

locals {
  infra_deployer_roles = [
    "roles/run.admin",                      # Manage Cloud Run
    "roles/iam.serviceAccountAdmin",        # Manage SAs
    "roles/iam.serviceAccountUser",         # Use SAs (deploy services as them)
    "roles/artifactregistry.admin",         # Manage AR repos
    "roles/secretmanager.admin",            # Manage secrets (not values)
    "roles/datastore.owner",                # Manage Firestore
    "roles/storage.admin",                  # Manage state bucket and any others
    "roles/serviceusage.serviceUsageAdmin", # Enable APIs
    "roles/iam.workloadIdentityPoolAdmin",  # Manage WIF (Slice 4)
    "roles/compute.networkAdmin",           # VPC connector (B will use)
    "roles/redis.admin",                    # Memorystore (B will use)
    "roles/monitoring.editor"               # Alert policies (B will use)
  ]
}

resource "google_project_iam_member" "infra_deployer_roles" {
  for_each = toset(local.infra_deployer_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.infra_deployer.email}"
}