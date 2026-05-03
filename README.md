# url-shortener-infra

Terraform infrastructure for the SWE 455 URL Shortener project.

## Prerequisites

- Terraform >= 1.9.0
- Google Cloud SDK (`gcloud`)
- A GCP project with billing enabled
- A GCS bucket for Terraform state (must be created manually before first `terraform init` — see "Bootstrap" below)

## Bootstrap (one-time)

These steps must be done **once per GCP project**, manually, before Terraform can manage anything else:

1. Create the GCP project, link a billing account, and authenticate:
```bash
   gcloud auth login
   gcloud auth application-default login
   gcloud auth application-default set-quota-project <project-id>
   gcloud config set project <project-id>
```

2. Enable the bootstrap APIs Terraform itself needs:
```bash
   gcloud services enable cloudresourcemanager.googleapis.com iam.googleapis.com serviceusage.googleapis.com
```

3. Create the GCS bucket for Terraform state:
```bash
   gsutil mb -p <project-id> -l <region> -b on gs://<state-bucket-name>
   gsutil versioning set on gs://<state-bucket-name>
```

4. Update `backend.tf` with your bucket name.

## Setup

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values
terraform init
terraform plan
terraform apply
```
## Secret Manager — populating values

The infra creates two empty secrets in Secret Manager. Their values must be populated manually once, after the first `terraform apply`:

### `shortener-api-key`

Used by the shortener service to authenticate `POST /api/urls` requests (Factor 15).

```bash
# Generate a random 32-byte hex string and add as a new secret version
gcloud secrets versions add shortener-api-key \
  --data-file=- \
  --project=swe455-urlshortener-252 <<< "$(openssl rand -hex 32)"
```

On Windows (PowerShell):
```powershell
$key = -join ((1..64) | ForEach-Object { '{0:x}' -f (Get-Random -Maximum 16) })
$key | gcloud secrets versions add shortener-api-key --data-file=- --project=swe455-urlshortener-252
```

### `redis-auth-string`

Populated by Member B when the Memorystore (Redis) instance is provisioned. The auth string is set on the Redis instance itself; B will read it back from `terraform output` and store it here.

### Inspecting

```bash
gcloud secrets list --project=swe455-urlshortener-252
gcloud secrets versions list shortener-api-key --project=swe455-urlshortener-252
```

## Layout

- `versions.tf` — Terraform and provider version pins
- `backend.tf` — GCS backend config for remote state
- `providers.tf` — Google provider config
- `variables.tf` / `terraform.tfvars` — input variables
- `main.tf` — root module wiring
- `modules/` — reusable modules
  - `apis/` — enables required GCP APIs
  - (more modules will be added in later slices)