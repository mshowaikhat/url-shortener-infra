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

output "shortener_deployer_sa_email" {
  value = module.iam.shortener_deployer_sa_email
}

output "redirect_deployer_sa_email" {
  value = module.iam.redirect_deployer_sa_email
}

output "api_gateway_sa_email" {
  value = module.iam.api_gateway_sa_email
}

output "api_gateway_url" {
  description = "Public HTTPS URL of the deployed API Gateway"
  value       = "https://${module.api_gateway.gateway_default_hostname}"
}

output "migration_job_name" {
  description = "Cloud Run Job name — run with: gcloud run jobs execute shortener-migrate --region=us-central1"
  value       = module.migration_job.job_name
}

output "alert_policy_error_rate" {
  description = "Cloud Monitoring alert policy for high 5xx error rate"
  value       = module.alerting.error_rate_policy_name
}

output "alert_policy_latency_p95" {
  description = "Cloud Monitoring alert policy for high p95 latency"
  value       = module.alerting.latency_p95_policy_name
}