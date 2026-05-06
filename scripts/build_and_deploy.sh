#!/usr/bin/env bash
# Build both service images via Cloud Build, push to Artifact Registry,
# deploy to Cloud Run, and update the migration job's image.
#
# After `terraform apply` Cloud Run services exist but run the placeholder
# `cloudrun/container/hello` image. This script replaces that with real
# code in two parallel Cloud Build invocations.
#
# Image tags use the short git SHA when available (matches the CI tagging
# convention exactly — Factor 5 immutable releases) and fall back to a
# timestamp when no git history is available.

set -euo pipefail

PROJECT="${PROJECT:-swe455-urlshortener-252}"
REGION="${REGION:-us-central1}"
REPO="${REPO:-services}"

# Sibling-repo layout: ../url-shortener-service and ../url-redirect-service
SHORTENER_DIR="${SHORTENER_DIR:-../url-shortener-service}"
REDIRECT_DIR="${REDIRECT_DIR:-../url-redirect-service}"

if [ ! -d "$SHORTENER_DIR" ]; then
  echo "ERROR: shortener repo not found at $SHORTENER_DIR" >&2
  exit 1
fi
if [ ! -d "$REDIRECT_DIR" ]; then
  echo "ERROR: redirect repo not found at $REDIRECT_DIR" >&2
  exit 1
fi

git_sha_or_now() {
  git -C "$1" rev-parse --short HEAD 2>/dev/null || date +%Y%m%d-%H%M%S
}

SHORTENER_TAG="$(git_sha_or_now "$SHORTENER_DIR")"
REDIRECT_TAG="$(git_sha_or_now "$REDIRECT_DIR")"

AR_BASE="${REGION}-docker.pkg.dev/${PROJECT}/${REPO}"
SHORTENER_IMAGE="${AR_BASE}/shortener:${SHORTENER_TAG}"
REDIRECT_IMAGE="${AR_BASE}/redirect:${REDIRECT_TAG}"

# ---------------------------------------------------------------------------
# Builds (sequential; gcloud builds submit waits for completion)
# ---------------------------------------------------------------------------
echo "==> Building shortener image (tag=${SHORTENER_TAG})"
gcloud builds submit "$SHORTENER_DIR" \
  --tag="$SHORTENER_IMAGE" \
  --project="$PROJECT" \
  --quiet

echo ""
echo "==> Building redirect image (tag=${REDIRECT_TAG})"
gcloud builds submit "$REDIRECT_DIR" \
  --tag="$REDIRECT_IMAGE" \
  --project="$PROJECT" \
  --quiet

# ---------------------------------------------------------------------------
# Deploys
# ---------------------------------------------------------------------------
echo ""
echo "==> Deploying shortener -> ${SHORTENER_IMAGE}"
gcloud run deploy shortener \
  --image="$SHORTENER_IMAGE" \
  --region="$REGION" \
  --project="$PROJECT" \
  --quiet

echo ""
echo "==> Deploying redirect  -> ${REDIRECT_IMAGE}"
gcloud run deploy redirect \
  --image="$REDIRECT_IMAGE" \
  --region="$REGION" \
  --project="$PROJECT" \
  --quiet

# ---------------------------------------------------------------------------
# Migration job uses the shortener image with a command override.
# ---------------------------------------------------------------------------
echo ""
echo "==> Updating shortener-migrate job image"
gcloud run jobs update shortener-migrate \
  --image="$SHORTENER_IMAGE" \
  --region="$REGION" \
  --project="$PROJECT" \
  --quiet

echo ""
echo "BUILD & DEPLOY COMPLETE."
echo "    shortener: ${SHORTENER_IMAGE}"
echo "    redirect:  ${REDIRECT_IMAGE}"
echo "    job:       shortener-migrate (uses shortener image)"
