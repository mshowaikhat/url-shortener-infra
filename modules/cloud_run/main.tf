resource "google_cloud_run_v2_service" "this" {
  project  = var.project_id
  location = var.region
  name     = var.service_name

  ingress = "INGRESS_TRAFFIC_ALL"

  template {
    service_account = var.service_account_email

    scaling {
      min_instance_count = var.min_instances
      max_instance_count = var.max_instances
    }

    # The Cloud Run v2 provider returns null for manual_instance_count when
    # not set, but the resource's stored state has 0. We tell Terraform to
    # ignore this specific attribute to prevent perpetual diff noise.

    max_instance_request_concurrency = var.container_concurrency

    containers {
      image = var.image

      resources {
        limits = {
          cpu    = var.cpu
          memory = var.memory
        }
        cpu_idle          = true
        startup_cpu_boost = true
      }

      ports {
        container_port = 8080
      }

      dynamic "env" {
        for_each = var.env_vars
        content {
          name  = env.key
          value = env.value
        }
      }
    }
  }

  # The app pipeline owns the image after first deploy. Ignore image drift
  # so `terraform apply` doesn't roll back a real deployment.
  lifecycle {
    ignore_changes = [
      template[0].containers[0].image,
      client,
      client_version,
    ]
  }
}

# Public access (only if allow_public_access = true)
resource "google_cloud_run_v2_service_iam_member" "public_invoker" {
  count = var.allow_public_access ? 1 : 0

  project  = google_cloud_run_v2_service.this.project
  location = google_cloud_run_v2_service.this.location
  name     = google_cloud_run_v2_service.this.name
  role     = "roles/run.invoker"
  member   = "allUsers"
}