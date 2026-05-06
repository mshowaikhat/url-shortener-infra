variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "GCP region for the Cloud Run Job"
}

variable "job_name" {
  type        = string
  description = "Name of the Cloud Run Job resource"
}

variable "service_account_email" {
  type        = string
  description = "Service account the job container runs as"
}

variable "image" {
  type        = string
  description = "Container image (SHA-tagged). Managed by CI; Terraform ignores changes."
}

variable "command" {
  type        = list(string)
  description = "Container ENTRYPOINT override. Replaces the image's default ENTRYPOINT."
  default     = []
}

variable "env_vars" {
  type        = map(string)
  description = "Plain-text environment variables passed to the container"
  default     = {}
}

variable "secret_env_vars" {
  type = map(object({
    secret  = string
    version = string
  }))
  description = "Secret Manager–backed environment variables"
  default     = {}
}

variable "timeout" {
  type        = string
  description = "Maximum duration for a single task execution (e.g. \"600s\")"
  default     = "600s"
}

variable "max_retries" {
  type        = number
  description = "Number of retries on task failure (0 = no retry)"
  default     = 0
}
