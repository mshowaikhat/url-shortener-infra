output "secret_ids" {
  description = "Map of secret_id -> full resource name"
  value = {
    for k, s in google_secret_manager_secret.this : k => s.id
  }
}

output "secret_names" {
  description = "List of secret IDs created"
  value       = keys(google_secret_manager_secret.this)
}