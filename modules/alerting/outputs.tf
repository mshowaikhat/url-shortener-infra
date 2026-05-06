output "error_rate_policy_name" {
  description = "Resource name of the 5xx error-rate alert policy"
  value       = google_monitoring_alert_policy.error_rate.name
}

output "latency_p95_policy_name" {
  description = "Resource name of the p95 latency alert policy"
  value       = google_monitoring_alert_policy.latency_p95.name
}
