variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "region" {
  type        = string
  description = "Region for the Cloud Run service"
}

variable "service_name" {
  type        = string
  description = "Name of the Cloud Run service (e.g., 'shortener', 'redirect')"
}

variable "service_account_email" {
  type        = string
  description = "Service account the Cloud Run service runs as"
}

variable "image" {
  type        = string
  description = "Container image. Use a placeholder for first deploy; CI/CD overwrites it."
  default     = "us-docker.pkg.dev/cloudrun/container/hello"
}

variable "env_vars" {
  type        = map(string)
  description = "Plain-text environment variables (non-secret)"
  default     = {}
}

variable "min_instances" {
  type        = number
  description = "Minimum number of instances (0 allows scale-to-zero)"
  default     = 0
}

variable "max_instances" {
  type        = number
  description = "Maximum number of instances"
  default     = 5
}

variable "container_concurrency" {
  type        = number
  description = "Max concurrent requests per container instance"
  default     = 80
}

variable "memory" {
  type        = string
  description = "Memory limit (e.g., '256Mi', '512Mi', '1Gi')"
  default     = "256Mi"
}

variable "cpu" {
  type        = string
  description = "CPU limit (e.g., '1', '2')"
  default     = "1"
}

variable "allow_public_access" {
  type        = bool
  description = "If true, grant roles/run.invoker to allUsers (public)"
  default     = true
}