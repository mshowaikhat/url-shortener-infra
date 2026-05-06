resource "google_cloud_run_v2_job" "this" {
  project  = var.project_id
  location = var.region
  name     = var.job_name

  template {
    # task_count / parallelism default to 1 — one task, no fan-out.

    template {
      service_account = var.service_account_email
      max_retries     = var.max_retries
      timeout         = var.timeout

      containers {
        # Image is set here by Terraform on first apply, then kept in sync by
        # CI (gcloud run jobs update --image=...). Terraform ignores subsequent
        # image changes so plan output stays clean.
        image   = var.image
        command = length(var.command) > 0 ? var.command : null

        dynamic "env" {
          for_each = var.env_vars
          content {
            name  = env.key
            value = env.value
          }
        }

        dynamic "env" {
          for_each = var.secret_env_vars
          content {
            name = env.key
            value_source {
              secret_key_ref {
                secret  = env.value.secret
                version = env.value.version
              }
            }
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      template[0].template[0].containers[0].image,
      client,
      client_version,
    ]
  }
}
