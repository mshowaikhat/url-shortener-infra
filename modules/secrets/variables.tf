variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "secrets" {
  type = map(object({
    accessor_sa_emails = list(string)
  }))
  description = <<-EOT
    Map of secret_id -> { accessor_sa_emails = [...] }.
    Each secret is created with no value (B populates manually).
    The listed service accounts get roles/secretmanager.secretAccessor
    bound directly to the secret.
  EOT
}