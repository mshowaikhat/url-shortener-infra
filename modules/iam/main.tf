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
    "roles/datastore.user",               # Firestore read/write
    "roles/secretmanager.secretAccessor", # Read secrets at runtime
    "roles/logging.logWriter",            # stdout -> Cloud Logging
    "roles/monitoring.metricWriter",      # Custom metrics
    "roles/cloudtrace.agent"              # Send spans to Cloud Trace
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
    "roles/run.admin",
    "roles/iam.serviceAccountAdmin",
    "roles/iam.serviceAccountUser",
    "roles/artifactregistry.admin",
    "roles/secretmanager.admin",
    "roles/datastore.owner",
    "roles/storage.admin",
    "roles/serviceusage.serviceUsageAdmin",
    "roles/iam.workloadIdentityPoolAdmin",
    "roles/compute.networkAdmin",
    "roles/redis.admin",
    "roles/monitoring.editor",
    "roles/vpcaccess.admin",
    "roles/resourcemanager.projectIamAdmin" # NEW: required to read/modify project IAM bindings
  ]
}

resource "google_project_iam_member" "infra_deployer_roles" {
  for_each = toset(local.infra_deployer_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.infra_deployer.email}"
}

# ----- Per-service deployer SAs -----
# These SAs are impersonated by GitHub Actions in each service repo to push
# images and deploy to Cloud Run. They are NOT the runtime SAs.

resource "google_service_account" "shortener_deployer" {
  project      = var.project_id
  account_id   = "shortener-deployer-sa"
  display_name = "Shortener CI/CD Deployer (used by GitHub Actions via WIF)"
}

resource "google_service_account" "redirect_deployer" {
  project      = var.project_id
  account_id   = "redirect-deployer-sa"
  display_name = "Redirect CI/CD Deployer (used by GitHub Actions via WIF)"
}

locals {
  service_deployer_roles = [
    "roles/artifactregistry.writer", # Push images to AR
    "roles/run.developer",           # Deploy & update Cloud Run revisions
    "roles/iam.serviceAccountUser",  # Required: deploy a service that runs as another SA
  ]
}

resource "google_project_iam_member" "shortener_deployer_roles" {
  for_each = toset(local.service_deployer_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.shortener_deployer.email}"
}

resource "google_project_iam_member" "redirect_deployer_roles" {
  for_each = toset(local.service_deployer_roles)

  project = var.project_id
  role    = each.value
  member  = "serviceAccount:${google_service_account.redirect_deployer.email}"
}

# ----- actAs binding -----
# When `gcloud run deploy` says "run this container as shortener-sa",
# the deployer SA needs permission to "act as" that runtime SA.

resource "google_service_account_iam_member" "shortener_deployer_acts_as_runtime" {
  service_account_id = google_service_account.shortener.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.shortener_deployer.email}"
}

resource "google_service_account_iam_member" "redirect_deployer_acts_as_runtime" {
  service_account_id = google_service_account.redirect.name
  role               = "roles/iam.serviceAccountUser"
  member             = "serviceAccount:${google_service_account.redirect_deployer.email}"
}