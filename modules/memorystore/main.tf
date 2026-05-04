resource "google_redis_instance" "cache" {
  name           = "redis-cache"
  tier           = "BASIC"
  memory_size_gb = 1
  region         = var.region
  redis_version  = "REDIS_7_0"
  authorized_network = "default"

  auth_enabled = true
}