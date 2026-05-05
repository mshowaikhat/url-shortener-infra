terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
    }
    google-beta = {
      source = "hashicorp/google-beta"
    }
  }
}

locals {
  openapi_spec = templatefile("${path.module}/openapi.yaml.tpl", {
    api_id        = var.api_id
    shortener_url = var.shortener_url
  })
}

resource "google_api_gateway_api" "shortener" {
  provider = google-beta
  project  = var.project_id
  api_id   = var.api_id
}

resource "google_api_gateway_api_config" "shortener" {
  provider             = google-beta
  project              = var.project_id
  api                  = google_api_gateway_api.shortener.api_id
  api_config_id_prefix = "cfg-"

  openapi_documents {
    document {
      path     = "openapi.yaml"
      contents = base64encode(local.openapi_spec)
    }
  }

  gateway_config {
    backend_config {
      google_service_account = var.gateway_sa_email
    }
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "google_api_gateway_gateway" "shortener" {
  provider   = google-beta
  project    = var.project_id
  region     = var.region
  api_config = google_api_gateway_api_config.shortener.id
  gateway_id = var.gateway_id

  depends_on = [google_api_gateway_api_config.shortener]
}

# Allow the gateway SA to invoke the shortener Cloud Run service.
# (The shortener is also publicly invokable today, so this is additive
# defense-in-depth that lets us tighten public access later.)
resource "google_cloud_run_v2_service_iam_member" "gateway_invokes_shortener" {
  project  = var.project_id
  location = var.region
  name     = var.shortener_service_name
  role     = "roles/run.invoker"
  member   = "serviceAccount:${var.gateway_sa_email}"
}
