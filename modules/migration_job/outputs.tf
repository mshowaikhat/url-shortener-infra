output "job_name" {
  description = "Cloud Run Job name (use with `gcloud run jobs execute`)"
  value       = google_cloud_run_v2_job.this.name
}

output "job_id" {
  description = "Full resource ID of the Cloud Run Job"
  value       = google_cloud_run_v2_job.this.id
}
