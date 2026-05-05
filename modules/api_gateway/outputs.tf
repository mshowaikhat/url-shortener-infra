output "gateway_default_hostname" {
  description = "Default *.gateway.dev hostname assigned to the deployed gateway"
  value       = google_api_gateway_gateway.shortener.default_hostname
}

output "gateway_id" {
  value = google_api_gateway_gateway.shortener.gateway_id
}

output "api_config_id" {
  value = google_api_gateway_api_config.shortener.id
}
