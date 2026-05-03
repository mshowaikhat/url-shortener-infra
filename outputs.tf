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