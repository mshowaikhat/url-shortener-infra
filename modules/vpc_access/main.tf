resource "google_vpc_access_connector" "connector" {
  name          = "serverless-connector"
  region        = var.region
  network       = var.network
  ip_cidr_range = "10.8.0.0/28"
  min_instances = 2
  max_instances = 3
}