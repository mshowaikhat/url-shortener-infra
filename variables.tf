variable "project_id" {
  type        = string
  description = "GCP project ID where all resources are provisioned"
}

variable "region" {
  type        = string
  description = "GCP region for regional resources"
  default     = "us-central1"
}

variable "github_owner" {
  type        = string
  description = "GitHub username or org that owns the three repos"
}

variable "github_repo_shortener" {
  type        = string
  description = "Name of the shortener service GitHub repo"
  default     = "url-shortener-service"
}

variable "github_repo_redirect" {
  type        = string
  description = "Name of the redirect service GitHub repo"
  default     = "url-redirect-service"
}

variable "github_repo_infra" {
  type        = string
  description = "Name of the infra GitHub repo"
  default     = "url-shortener-infra"
}

variable "network" {
  type    = string
  default = "default"
}