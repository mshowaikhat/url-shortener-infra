locals {
  required_apis = [
    "run.googleapis.com",                 # Cloud Run
    "artifactregistry.googleapis.com",    # Container images
    "firestore.googleapis.com",           # Firestore (Native)
    "secretmanager.googleapis.com",       # Secret Manager
    "iam.googleapis.com",                 # IAM
    "iamcredentials.googleapis.com",      # WIF token exchange
    "sts.googleapis.com",                 # WIF (Security Token Service)
    "logging.googleapis.com",             # Cloud Logging
    "monitoring.googleapis.com",          # Cloud Monitoring
    "cloudtrace.googleapis.com",          # Cloud Trace
    "vpcaccess.googleapis.com",           # Serverless VPC Access (B will use)
    "redis.googleapis.com",               # Memorystore (B will use)
    "compute.googleapis.com",             # Already enabled, but declare it
    "cloudresourcemanager.googleapis.com" # Already enabled, declare anyway
  ]
}

module "apis" {
  source = "./modules/apis"

  project_id = var.project_id
  apis       = local.required_apis
}