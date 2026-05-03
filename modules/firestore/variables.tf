variable "project_id" {
  type        = string
  description = "GCP project ID"
}

variable "location_id" {
  type        = string
  description = "Firestore location (e.g., us-central1, nam5, eur3). Cannot be changed after creation."
  default     = "us-central1"
}