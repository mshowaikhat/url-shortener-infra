#!/usr/bin/env bash
# Demo-grade restore: take an empty (or partly destroyed) GCP project and
# bring it to a fully functional, smoke-tested state with one command.
#
# Steps:
#   1. terraform init (cheap if already done)
#   2. Re-import resources that survived destroy (Firestore, WIF pool/provider)
#   3. terraform apply  — recreates AR, Cloud Run, Memorystore, VPC, IAM,
#      Secret Manager (empty), API Gateway, migration job, alert policies
#   4. Seed Secret Manager values (API key + Redis auth)
#   5. Build images via Cloud Build, deploy to Cloud Run, update job image
#   6. Smoke test: direct path + gateway path, with Firestore cleanup
#
# Idempotent: safe to re-run after partial failure.

set -euo pipefail

PROJECT="${PROJECT:-swe455-urlshortener-252}"

echo "==> Step 1/5: terraform init"
terraform init -upgrade=false

echo ""
echo "==> Step 2/5: import protected resources back into state"

import_if_missing() {
  local addr="$1"
  local id="$2"
  local desc="$3"

  if terraform state list "$addr" >/dev/null 2>&1; then
    echo "    -> $desc already in state (skip)"
    return 0
  fi

  echo "    -> importing $desc"
  if terraform import "$addr" "$id" >/dev/null 2>&1; then
    echo "       OK"
  else
    echo "       (not found in GCP — apply will create it)"
  fi
}

import_if_missing \
  "module.firestore.google_firestore_database.default" \
  "projects/${PROJECT}/databases/(default)" \
  "Firestore (default) database"

import_if_missing \
  "module.workload_identity.google_iam_workload_identity_pool.github" \
  "projects/${PROJECT}/locations/global/workloadIdentityPools/github-pool" \
  "WIF pool 'github-pool'"

import_if_missing \
  "module.workload_identity.google_iam_workload_identity_pool_provider.github" \
  "projects/${PROJECT}/locations/global/workloadIdentityPools/github-pool/providers/github-provider" \
  "WIF provider 'github-provider'"

echo ""
echo "==> Step 3/5: terraform apply"
echo "    (Memorystore + VPC connector are slow — expect ~10 min)"
terraform apply -auto-approve

echo ""
echo "==> Step 4/5: seed Secret Manager values"
bash scripts/seed_secrets.sh

echo ""
echo "==> Step 5/5: build & deploy services, then smoke test"
bash scripts/build_and_deploy.sh

echo ""
echo "==> Smoke test"
API_KEY="$(gcloud secrets versions access latest \
  --secret=shortener-api-key \
  --project=${PROJECT})" \
  bash scripts/smoke_test.sh

echo ""
echo "================================="
echo "RESTORE COMPLETE — system healthy"
echo "================================="
