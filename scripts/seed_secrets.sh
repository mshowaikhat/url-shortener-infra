#!/usr/bin/env bash
# Populate Secret Manager values that Terraform deliberately leaves empty.
#
# Terraform creates the `google_secret_manager_secret` resources but never
# the `_version` resources — secret VALUES never live in state, tfvars, or
# git. After a fresh apply each secret has zero versions, so any service
# trying to read 'latest' gets a 404. This script repopulates them.
#
# Both `gcloud secrets versions add` invocations use stdin pipes with
# `tr -d '\r\n'` to strip line endings — Git Bash on Windows otherwise
# corrupts the values with a trailing CRLF (lesson learned the hard way).

set -euo pipefail

PROJECT="${PROJECT:-swe455-urlshortener-252}"
REGION="${REGION:-us-central1}"

# ---------------------------------------------------------------------------
# 1. shortener-api-key
#    Generate a fresh 32-byte base64 key. Strip '=' padding so the resulting
#    string is URL-safe and curl-friendly.
# ---------------------------------------------------------------------------
echo "==> Generating fresh shortener-api-key"
openssl rand -base64 32 \
  | tr -d '\r\n=' \
  | gcloud secrets versions add shortener-api-key \
      --data-file=- \
      --project="$PROJECT"
echo "    -> shortener-api-key: new version added"

# ---------------------------------------------------------------------------
# 2. redis-auth-string
#    Memorystore generates this on instance creation. We just have to
#    fetch it and hand it to Secret Manager — ZERO transformation, in
#    particular ZERO line endings.
# ---------------------------------------------------------------------------
echo ""
echo "==> Fetching Memorystore auth string"
gcloud redis instances get-auth-string redis-cache \
  --region="$REGION" \
  --project="$PROJECT" \
  --format='value(authString)' \
  | tr -d '\r\n' \
  | gcloud secrets versions add redis-auth-string \
      --data-file=- \
      --project="$PROJECT"
echo "    -> redis-auth-string: new version added"

# ---------------------------------------------------------------------------
# Sanity check: secret byte counts should match the source values.
# ---------------------------------------------------------------------------
echo ""
echo "==> Verifying secret byte counts"
api_bytes=$(gcloud secrets versions access latest \
  --secret=shortener-api-key --project="$PROJECT" | wc -c)
redis_bytes=$(gcloud secrets versions access latest \
  --secret=redis-auth-string --project="$PROJECT" | wc -c)
echo "    shortener-api-key   = ${api_bytes} bytes"
echo "    redis-auth-string   = ${redis_bytes} bytes (Memorystore UUID is 36)"

if [ "$redis_bytes" != "36" ]; then
  echo "WARNING: redis-auth-string is not 36 bytes — Memorystore may reject it." >&2
fi

echo ""
echo "SECRETS SEEDED."
