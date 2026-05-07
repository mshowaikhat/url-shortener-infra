# url-shortener-infra

Terraform infrastructure for the SWE 455 (Cloud Applications Engineering) URL shortener project at KFUPM. Provisions every GCP resource the system needs and orchestrates the demo-grade `make destroy && make restore` flow.

Companion service repos:

- [`url-shortener-service`](https://github.com/mshowaikhat/url-shortener-service)
- [`url-redirect-service`](https://github.com/mshowaikhat/url-redirect-service)

---

## What this provisions

| Module | Purpose |
|---|---|
| `apis` | Enables required GCP APIs |
| `iam` | Runtime + deployer service accounts and IAM bindings |
| `workload_identity` | WIF pool + OIDC provider + per-repo SA bindings (no SA keys) |
| `firestore` | Firestore native-mode database (collection `urls`) |
| `artifact_registry` | Docker repository for service images (SHA tags) |
| `secrets` | Secret Manager parents for `shortener-api-key`, `redis-auth-string` |
| `vpc_access` | Serverless VPC connector (Cloud Run → Memorystore) |
| `memorystore` | Redis BASIC 1 GB with AUTH enabled |
| `cloud_run` | Both Cloud Run services (`shortener` + `redirect`) |
| `migration_job` | Cloud Run Job for Factor 12 admin processes |
| `api_gateway` | API Gateway in front of the shortener service (X-API-Key passes through) |
| `alerting` | Cloud Monitoring alert policies (5xx rate + p95 latency) |

All images are SHA-tagged (no `:latest`). Secret values are **never** in Terraform — only the parent secret resources are. Values are seeded by `scripts/seed_secrets.sh` after the first apply.

---

## Prerequisites

- Terraform ≥ 1.9
- Google Cloud SDK (`gcloud`)
- A GCP project with billing enabled
- A GCS bucket for Terraform remote state (created manually before first `terraform init`)

---

## Bootstrap (one-time per project)

```bash
gcloud auth login
gcloud auth application-default login
gcloud auth application-default set-quota-project <project-id>
gcloud config set project <project-id>

gcloud services enable \
  cloudresourcemanager.googleapis.com \
  iam.googleapis.com \
  serviceusage.googleapis.com

gsutil mb -p <project-id> -l <region> -b on gs://<state-bucket-name>
gsutil versioning set on gs://<state-bucket-name>
```

Then update `backend.tf` with your bucket name.

---

## Setup

```bash
cp terraform.tfvars.example terraform.tfvars
# Edit terraform.tfvars with your values (project_id, region, github_owner, etc.)
terraform init
terraform plan
terraform apply
```

After the first apply, seed Secret Manager:

```bash
make seed-secrets
```

This populates both `shortener-api-key` (random 32-byte base64) and `redis-auth-string` (read back from Memorystore).

---

## Demo: destroy and restore

The instructor demo requires being able to delete the entire cloud environment and bring it back to a fully working, smoke-tested state in minutes. That's what `make destroy` and `make restore` do.

```bash
make destroy   # ~10 min
make restore   # ~15 min, ends with a smoke-test gate
```

`destroy` first runs `terraform state rm` on three protected resources (Firestore, WIF pool, WIF provider) so they survive in GCP — Firestore has `prevent_destroy = true` on purpose (re-enabling it can take days), and the WIF resources are soft-deleted by GCP for 30 days which would block recreation.

`restore` is six idempotent steps:

1. `terraform init`
2. Re-import the three protected resources
3. Phase-1 apply: `-target=module.secrets -target=module.redis` (Memorystore + secret parents)
4. Seed Secret Manager values
5. Full `terraform apply` (creates Cloud Run services, gateway, job, etc.)
6. `gcloud builds submit` × 2, `gcloud run deploy` × 2, `gcloud run jobs update`, then a smoke test against direct + gateway paths

Both targets are safe to re-run after a partial failure.

---

## Makefile targets

| Target | What it does |
|---|---|
| `make help` | List targets |
| `make destroy` | `terraform state rm` protected resources, then `terraform destroy` |
| `make restore` | Full restore: import + phased apply + seed + build + deploy + verify |
| `make seed-secrets` | Repopulate `shortener-api-key` and `redis-auth-string` |
| `make build-and-deploy` | Cloud Build images, deploy services, update migration job |
| `make smoke-test` (`verify`) | Direct + gateway path checks with Firestore cleanup |

All targets shell out to scripts in `scripts/`.

---

## CI/CD

`.github/workflows/terraform.yml` runs `terraform plan` on PRs and `terraform apply` on push to `main`. Authentication uses **Workload Identity Federation** — there are no service-account keys stored in GitHub Secrets.

---

## Repository layout

```
main.tf                  # Root module wiring
variables.tf             # Inputs
outputs.tf               # Outputs
versions.tf              # Terraform + provider pins
providers.tf             # google + google-beta providers
backend.tf               # GCS remote state config

modules/
  apis/                  # Required GCP APIs
  iam/                   # Service accounts + bindings
  workload_identity/     # WIF pool + provider + repo bindings
  firestore/             # Firestore database (prevent_destroy)
  artifact_registry/     # Docker repository
  secrets/               # Secret Manager parents
  vpc_access/            # VPC serverless connector
  memorystore/           # Redis (BASIC 1 GB, AUTH)
  cloud_run/             # Cloud Run service (used twice)
  migration_job/         # Cloud Run Job (Factor 12)
  api_gateway/           # API Gateway + Swagger 2.0 spec
  alerting/              # Cloud Monitoring alert policies

scripts/
  destroy.sh             # state rm + terraform destroy
  restore.sh             # 6-step idempotent restore
  seed_secrets.sh        # populate Secret Manager values
  build_and_deploy.sh    # Cloud Build + Cloud Run deploy
  smoke_test.sh          # direct + gateway smoke tests w/ Firestore cleanup

Makefile                 # thin wrapper over scripts/
```

---

## Notes & gotchas

- **`/healthz` is reserved by Cloud Run.** Both services use `/livez` and `/readyz`. Do not change this.
- **Firestore `prevent_destroy = true`** is intentional. So is the destroy/restore script's special handling of WIF (GCP soft-deletes WIF resources for 30 days).
- **Cosmetic scaling diff** on Cloud Run plan output (`min_instance_count` going `0 → null`) is a Google provider quirk — harmless, reappears every plan.
- **`terraform.tfvars` is gitignored.** Never commit it.
- **No `:latest` tags** anywhere — Factor 5.

---

## License & course context

KFUPM SWE 455 Term 252 course project.
