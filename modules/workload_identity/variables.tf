variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "project_number" {
  type        = string
  description = "GCP project number (read at root from data.google_project to avoid depends_on cascades)"
}

variable "github_owner" {
  type        = string
  description = "GitHub username or org (e.g., 'mshowaikhat')"
}

variable "pool_id" {
  type        = string
  description = "Workload Identity Pool ID"
  default     = "github-pool"
}

variable "provider_id" {
  type        = string
  description = "Workload Identity Pool Provider ID"
  default     = "github-provider"
}

variable "repo_to_sa_bindings" {
  type = map(object({
    repo_name = string
    sa_email  = string
  }))
  description = "Map of binding name -> {repo_name, sa_email}. Each repo can impersonate the listed SA."
}