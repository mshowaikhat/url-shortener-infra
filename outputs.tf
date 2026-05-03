output "artifact_registry_url" {
  description = "Full URL prefix for pushing container images"
  value       = module.artifact_registry.repository_url
}

output "shortener_sa_email" {
  value = module.iam.shortener_sa_email
}

output "redirect_sa_email" {
  value = module.iam.redirect_sa_email
}

output "infra_deployer_sa_email" {
  value = module.iam.infra_deployer_sa_email
}

output "firestore_database" {
  value = module.firestore.database_name
}

output "shortener_url" {
  description = "Public URL of the shortener Cloud Run service"
  value       = module.shortener_service.service_url
}

output "redirect_url" {
  description = "Public URL of the redirect Cloud Run service"
  value       = module.redirect_service.service_url
}

output "wif_provider_name" {
  description = "Pass this as 'workload_identity_provider' in github-actions/auth@v2"
  value       = module.workload_identity.provider_name
}

output "wif_pool_name" {
  value = module.workload_identity.pool_name
}

output "project_number" {
  value = module.workload_identity.project_number
}

output "secret_names" {
  description = "Secret Manager secrets created (values must be populated manually)"
  value       = module.secrets.secret_names
}