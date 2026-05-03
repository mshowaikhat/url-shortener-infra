output "pool_name" {
  description = "Full WIF pool resource name (used in github-actions/auth)"
  value       = google_iam_workload_identity_pool.github.name
}

output "provider_name" {
  description = "Full WIF provider resource name. Pass as workload_identity_provider in github-actions/auth"
  value       = google_iam_workload_identity_pool_provider.github.name
}

output "project_number" {
  value = data.google_project.this.number
}