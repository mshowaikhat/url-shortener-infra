terraform {
  backend "gcs" {
    bucket = "swe455-urlshortener-tfstate-mhm14"
    prefix = "infra"
  }
}