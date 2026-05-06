variable "project_id" {
  type        = string
  description = "GCP project ID where alert policies are created"
}

variable "error_rate_threshold" {
  type        = number
  description = "5xx request rate (req/s) that triggers the error-rate alert"
  default     = 1.0
}

variable "latency_p95_threshold_ms" {
  type        = number
  description = "p95 request latency (milliseconds) that triggers the latency alert"
  default     = 2000
}

variable "notification_channel_ids" {
  type        = list(string)
  description = "Cloud Monitoring notification channel resource names to notify on alert"
  default     = []
}
