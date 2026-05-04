# SWE 455 Technical Report

## 1. Architecture

### Diagram
(Insert diagram image here or link from /docs/architecture.png)

### Narrative
This system consists of:
- URL Shortener service (Cloud Run)
- Redirect service (Cloud Run)
- Firestore database
- Artifact Registry for container images
- Terraform-managed infrastructure
- GitHub Actions CI/CD using Workload Identity Federation

---

## 2. REST API Documentation

### Shortener API
OpenAPI file:
- path: `../url-shortener-service/openapi.yaml`

### Redirect API
OpenAPI file:
- path: `../url-redirect-service/openapi.yaml`

(Attach rendered version or link generated docs if available)

---

## 3. 15-Factor Compliance

> NOTE: Fill file paths are already included; only adjust if your repo differs.

### Factor 1: Codebase
- Single repo per service:
  - `url-shortener-service/`
  - `url-redirect-service/`

### Factor 2: Dependencies
- `requirements.txt` or `pyproject.toml`

### Factor 3: Config
- Environment variables in:
  - `main.py`
  - Cloud Run service definitions (Terraform)

### Factor 4: Backing Services
- Firestore used via:
  - `google_firestore_database`
  - Terraform module: `modules/firestore/`

### Factor 5: Build, Release, Run
- CI/CD pipeline:
  - `.github/workflows/*.yml`

### Factor 6: Processes
- Stateless Cloud Run services

### Factor 7: Port Binding
- `PORT=8080` in container env

### Factor 8: Concurrency
- Cloud Run config in Terraform:
  - `max_instance_request_concurrency`

### Factor 9: Disposability
- Cloud Run auto-scaling + stateless design

### Factor 10: Dev/Prod Parity
- Terraform used for both environments

### Factor 11: Logs
- Cloud Logging enabled via default Cloud Run

### Factor 12: Admin Processes
- Terraform used for infra operations

### Factor 13: One Codebase, Many Deploys
- Separate Cloud Run services from same infra project

### Factor 14: CI/CD
- GitHub Actions using WIF:
  - `workload_identity/`

### Factor 15: Observability
- Logging + OpenTelemetry env vars:
  - `OTEL_SERVICE_NAME`

---

## 4. CI/CD Pipeline

Defined in:
- `.github/workflows/`

Steps:
1. Build Docker image
2. Push to Artifact Registry
3. Deploy to Cloud Run using Terraform or gcloud
4. Run smoke tests

---

## 5. Demo Procedure

1. Run `terraform apply`
2. Trigger GitHub Actions deployment
3. Call shortener endpoint:
   ```bash
   curl -X POST ...