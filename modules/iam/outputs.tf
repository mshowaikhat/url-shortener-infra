output "shortener_sa_email" {
  value = google_service_account.shortener.email
}

output "redirect_sa_email" {
  value = google_service_account.redirect.email
}

output "infra_deployer_sa_email" {
  value = google_service_account.infra_deployer.email
}