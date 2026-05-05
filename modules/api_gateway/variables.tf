variable "project_id" {
  type = string
}

variable "region" {
  type        = string
  description = "GCP region for the gateway control-plane resources"
}

variable "gateway_sa_email" {
  type        = string
  description = "Service account email the gateway uses to invoke backends"
}

variable "shortener_url" {
  type        = string
  description = "Public URL of the shortener Cloud Run service (no trailing slash)"
}

variable "shortener_service_name" {
  type        = string
  description = "Cloud Run service name of the shortener (for IAM binding)"
}

variable "api_id" {
  type        = string
  default     = "shortener-api"
  description = "Identifier for the API Gateway API resource"
}

variable "gateway_id" {
  type        = string
  default     = "shortener-gateway"
  description = "Identifier for the deployed Gateway resource"
}
