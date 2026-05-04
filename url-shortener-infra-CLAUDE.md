# url-shortener-infra — Repo Context

This is the Terraform repository. It provisions every GCP resource the URL shortener uses. **No application code lives here.** The two Cloud Run services use placeholder image references; the actual images are pushed by the service repos' CI/CD pipelines.

If you have not read the parent `swe455/CLAUDE.md`, do that first. This file assumes you have.

---

## Layout

```
url-shortener-infra/
├── .github/workflows/terraform.yml   # CI: terraform fmt, validate, plan, apply
├── Makefile                          # destroy / restore / smoke-test targets
├── backend.tf                        # GCS state backend
├── providers.tf                      # google + google-beta providers
├── versions.tf                       # pins Terraform >=1.9, google ~>6.0
├── variables.tf                      # input variables (project_id, region, github_owner, ...)
├── terraform.tfvars                  # gitignored, holds actual values
├── terraform.tfvars.example          # committed template
├── main.tf                           # root module: wires submodules
├── outputs.tf                        # exports SA emails, URLs, etc.
└── modules/
    ├── apis/                         # enables 14 GCP APIs
    ├── artifact_registry/            # Docker repo 'services'
    ├── cloud_run/                    # reusable; instantiated for shortener + redirect
    ├── firestore/                    # Native mode database, prevent_destroy=true
    ├── iam/                          # 5 service accounts + role bindings + actAs bindings
    ├── memorystore/                  # 1GB Basic Redis instance with auth
    ├── secrets/                      # Secret Manager secrets (no values)
    ├── vpc_access/                   # Serverless VPC connector for Cloud Run -> Memorystore
    └── workload_identity/            # Pool, OIDC provider, per-repo bindings
```

There are no `cloud_run_job/`, `monitoring/`, or `api_gateway/` modules yet. Adding them is part of your scope.

---

## What's deployed right now

Confirmed live and consistent with Terraform state as of this writing. Spot-check before doing work:

```bash
terraform refresh
terraform plan        # should show only the harmless 'scaling' block drift
```

If `plan` shows other changes, investigate before applying.

---

## Lifecycle protections

These are intentional and must NOT be removed:

- `module.firestore.google_firestore_database.default` — has `lifecycle { prevent_destroy = true }`. Firestore can only exist once per project; recreating it is a multi-day ordeal. Do not remove.
- `module.workload_identity.google_iam_workload_identity_pool.github` — same protection. WIF pools have a 30-day soft-delete window where the same name is reserved. Do not remove.
- `module.workload_identity.google_iam_workload_identity_pool_provider.github` — same.

The Makefile destroy target handles these by removing them from Terraform state (not from GCP) before running `terraform destroy`. The restore target re-imports them before `terraform apply`. **Read `Makefile` before changing the destroy/restore flow.**

---

## Cloud Run module gotcha

`modules/cloud_run/main.tf` has:

```hcl
lifecycle {
  ignore_changes = [
    template[0].containers[0].image,
    client,
    client_version,
  ]
}
```

This is critical. Terraform owns the *shell* of the Cloud Run service (env vars, scaling config, IAM); the service repos' CI/CD owns the *image*. Without `ignore_changes` on `image`, every `terraform apply` would try to roll back the image to the placeholder.

If you ever see Terraform planning to change a Cloud Run service's image, something is wrong — do not apply.

---

## Secrets — do NOT commit values

The `secrets/` module creates Secret Manager *resources* (named containers). Values are populated manually via gcloud, once, and never appear in:

- This Terraform repo
- Terraform state
- Git history
- CI logs
- Chat output

If you need to add a new secret value, the documented process is:

```bash
# Generate value out-of-band (or read from another source)
# Then:
echo -n "<value>" | gcloud secrets versions add <secret-name> --data-file=- --project=swe455-urlshortener-252
```

Or for a temporary file approach (Windows cmd):

```cmd
echo <value> > %TEMP%\secret.txt
gcloud secrets versions add <secret-name> --data-file="%TEMP%\secret.txt" --project=swe455-urlshortener-252
del %TEMP%\secret.txt
```

---

## CI/CD for this repo

`.github/workflows/terraform.yml`:

- On pull request: `terraform fmt -check`, `terraform validate`, `terraform plan` (no apply)
- On push to main: `terraform apply -auto-approve`
- Authenticates as `infra-deployer-sa` via Workload Identity Federation

`infra-deployer-sa` was granted these roles cumulatively across the project, including via manual one-time grants (because the SA can't grant itself permissions):

- Standard ones in `modules/iam/main.tf`'s `local.infra_deployer_roles`
- Manual: `roles/resourcemanager.projectIamAdmin`
- Manual: `roles/vpcaccess.admin`

If you add a new resource type that needs a new IAM role for the SA, add the role to `local.infra_deployer_roles` in `modules/iam/main.tf` AND grant it manually first via gcloud (otherwise the apply will fail trying to grant itself the role it needs to grant itself).

---

## Adding a new module

When you add a module (e.g., `modules/api_gateway/`):

1. Create `main.tf`, `variables.tf`, `outputs.tf` in the new directory
2. Add a `module "..."` block in root `main.tf` to wire it up
3. Run `terraform init` to download the module (Terraform discovers new submodules at init time, not plan time)
4. Run `terraform fmt -recursive` (CI checks formatting and will fail without this)
5. Run `terraform plan` to verify the additions
6. Commit and push — CI applies on main
7. If the apply fails on permissions, the deployer SA likely needs a new role. Add it to `local.infra_deployer_roles` AND grant manually via gcloud, then re-trigger CI.

---

## Where outputs go

`outputs.tf` at the root re-exports anything modules expose. Always add new outputs for resources another module or another repo will need to reference (e.g., a new connector's name, a new instance host).

---

## Common operations cheat sheet

```bash
# Test the destroy/restore cycle (used by demo)
make destroy
make restore
make smoke-test

# Force unlock state if stuck
terraform force-unlock <lock-id-from-error>

# Re-import a resource that's in GCP but not in state
terraform import <module.path.resource_address> <gcp-resource-id>

# Remove a resource from state without destroying it in GCP
terraform state rm <module.path.resource_address>

# See what's in state
terraform state list
terraform state show <address>
```
