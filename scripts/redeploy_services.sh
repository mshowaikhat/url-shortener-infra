#!/usr/bin/env bash
set -e

PROJECT="swe455-urlshortener-252"
REGION="us-central1"

SHORTENER_IMAGE="us-central1-docker.pkg.dev/swe455-urlshortener-252/services/shortener@sha256:4dfe0501c29920d5318251ccb7166b12c436861c6ab2f95c0b646f21f9d45fb5"

REDIRECT_IMAGE="us-central1-docker.pkg.dev/swe455-urlshortener-252/services/redirect@sha256:c4e258418054285d27c1ea8cf35d77a134204bcf0a89a67656f7a3346ca74381"

echo "Deploying shortener..."

gcloud run deploy shortener \
  --image $SHORTENER_IMAGE \
  --region $REGION \
  --platform managed \
  --quiet

echo "Deploying redirect..."

gcloud run deploy redirect \
  --image $REDIRECT_IMAGE \
  --region $REGION \
  --platform managed \
  --quiet

echo "Done."