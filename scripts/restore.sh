#!/usr/bin/env bash
# Demo-grade restore: take an empty (or partly destroyed) GCP project and
# bring it to a fully functional, smoke-tested state with one command.
#
# Steps:
#   1. terraform init.
#   2. Re-import resources that survived destroy (Firestore, WIF pool, WIF
#      provider — see destroy.sh for why they're not in state after destroy).
#   3. terraform apply phase 1: -target the resources needed BEFORE secret
#      values can be seeded — Memorystore (provides Redis auth string) and
#      Secret Manager (the parent secret resources). The redirect Cloud Run
#      service is excluded because it validates secret references at create
#      time and would fail with no versions.
#   4. seed_secrets.sh — generate API key, fetch Redis auth, populate secret
#      versions. Both via stdin pipes with `tr -d '\r\n'` (Git Bash CRLF fix).
#   5. terraform apply phase 2: full apply (now redirect_service can
#      successfully reference redis-auth-string/versions/latest).
#   6. build_and_deploy.sh — gcloud builds submit against sibling service
#      repos, gcloud run deploy with SHA tags, gcloud run jobs update for
#      the migration job.
#   7. Smoke test gate (direct + gateway paths). Restore exits non-zero if
#      either path fails.
#
# Idempotent: safe to re-run after partial failure.

set -euo pipefail

PROJECT="${PROJECT:-swe455-urlshortener-252}"

echo "==> Step 1/6: terraform init"
terraform init -upgrade=false

echo ""
echo "==> Step 2/6: import protected resources back into state"

import_if_missing() {
  local addr="$1"
  local id="$2"
  local desc="$3"

  # `terraform state list <addr>` returns exit 0 even when state is empty
  # (or the resource isn't tracked) — must check the output content, not
  # the exit code.
  if [ -n "$(terraform state list "$addr" 2>/dev/null)" ]; then
    echo "    -> $desc already in state (skip)"
    return 0
  fi

  echo "    -> importing $desc"
  if terraform import "$addr" "$id"; then
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
echo "==> Step 3/6: terraform apply phase 1 (secrets parents + Memorystore)"
echo "    Memorystore is slow — expect ~5-10 min."
# -target propagates dependencies, so this also brings up apis, iam, vpc,
# firestore, artifact_registry, alerting, workload_identity, and the secret
# parent resources.
terraform apply -auto-approve \
  -target=module.secrets \
  -target=module.redis

echo ""
echo "==> Step 4/6: seed Secret Manager values"
bash scripts/seed_secrets.sh

echo ""
echo "==> Step 5/6: terraform apply phase 2 (full apply)"
echo "    Creates redirect Cloud Run service (now that secret has a version)"
echo "    plus shortener service, migration job, API gateway, etc."
terraform apply -auto-approve

echo ""
echo "==> Step 6/6: build & deploy services, then smoke test"
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
