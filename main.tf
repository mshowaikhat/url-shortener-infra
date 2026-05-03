locals {
  required_apis = [
    "run.googleapis.com",
    "artifactregistry.googleapis.com",
    "firestore.googleapis.com",
    "secretmanager.googleapis.com",
    "iam.googleapis.com",
    "iamcredentials.googleapis.com",
    "sts.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "cloudtrace.googleapis.com",
    "vpcaccess.googleapis.com",
    "redis.googleapis.com",
    "compute.googleapis.com",
    "cloudresourcemanager.googleapis.com"
  ]
}

module "apis" {
  source = "./modules/apis"

  project_id = var.project_id
  apis       = local.required_apis
}

module "artifact_registry" {
  source = "./modules/artifact_registry"

  project_id = var.project_id
  region     = var.region

  depends_on = [module.apis]
}

module "iam" {
  source = "./modules/iam"

  project_id = var.project_id

  depends_on = [module.apis]
}

module "firestore" {
  source = "./modules/firestore"

  project_id  = var.project_id
  location_id = var.region

  depends_on = [module.apis]
}

module "shortener_service" {
  source = "./modules/cloud_run"

  project_id            = var.project_id
  region                = var.region
  service_name          = "shortener"
  service_account_email = module.iam.shortener_sa_email

  env_vars = {
    GCP_PROJECT_ID         = var.project_id
    FIRESTORE_COLLECTION   = "urls"
    LOG_LEVEL              = "INFO"
    OTEL_SERVICE_NAME      = "shortener"
    REDIRECT_BASE_URL      = "https://redirect-142958366034.us-central1.run.app"
  }

  min_instances = 0
  max_instances = 5
  memory        = "256Mi"

  depends_on = [
    module.apis,
    module.firestore,
    module.iam,
  ]
}

module "redirect_service" {
  source = "./modules/cloud_run"

  project_id            = var.project_id
  region                = var.region
  service_name          = "redirect"
  service_account_email = module.iam.redirect_sa_email

  env_vars = {
    GCP_PROJECT_ID       = var.project_id
    FIRESTORE_COLLECTION = "urls"
    LOG_LEVEL            = "INFO"
    OTEL_SERVICE_NAME    = "redirect"
  }

  min_instances = 0 # B will tune this to 1 in their slice for low cold-start latency
  max_instances = 10
  memory        = "256Mi"

  depends_on = [
    module.apis,
    module.firestore,
    module.iam,
  ]
}

module "workload_identity" {
  source = "./modules/workload_identity"

  project_id   = var.project_id
  github_owner = var.github_owner

  repo_to_sa_bindings = {
    shortener = {
      repo_name = var.github_repo_shortener
      sa_email  = module.iam.shortener_deployer_sa_email   # was: shortener_sa_email
    }
    redirect = {
      repo_name = var.github_repo_redirect
      sa_email  = module.iam.redirect_deployer_sa_email    # was: redirect_sa_email
    }
    infra = {
      repo_name = var.github_repo_infra
      sa_email  = module.iam.infra_deployer_sa_email
    }
  }

  depends_on = [
    module.apis,
    module.iam,
  ]
}

module "secrets" {
  source = "./modules/secrets"

  project_id = var.project_id

  secrets = {
    shortener-api-key = {
      accessor_sa_emails = [module.iam.shortener_sa_email]
    }
    redis-auth-string = {
      accessor_sa_emails = [module.iam.redirect_sa_email]
    }
  }

  depends_on = [
    module.apis,
    module.iam,
  ]
}