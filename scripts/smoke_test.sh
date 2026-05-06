#!/usr/bin/env bash
# Smoke test for the URL shortener system.
#
# Tests two paths:
#   1. Direct: POST shortener -> GET redirect -> assert 302 + Location
#   2. Gateway: POST via API Gateway -> GET redirect -> assert 302 + Location
#
# On exit, deletes all Firestore documents created during the run if gcloud
# is authenticated (best-effort; failures do not affect the test result).
#
# Required: API_KEY env var (the shortener-api-key Secret Manager value).
# Optional env overrides: SHORTENER_URL, REDIRECT_URL, GATEWAY_URL,
#                         GCP_PROJECT, TEST_LONG_URL.

set -euo pipefail

SHORTENER_URL="${SHORTENER_URL:-https://shortener-142958366034.us-central1.run.app}"
REDIRECT_URL="${REDIRECT_URL:-https://redirect-142958366034.us-central1.run.app}"
GATEWAY_URL="${GATEWAY_URL:-https://shortener-gateway-1to9px76.uc.gateway.dev}"
GCP_PROJECT="${GCP_PROJECT:-swe455-urlshortener-252}"
TEST_LONG_URL="${TEST_LONG_URL:-https://example.com/swe455-smoke-test}"

if [ -z "${API_KEY:-}" ]; then
  echo "ERROR: API_KEY env var is required." >&2
  echo 'Hint: API_KEY="$(gcloud secrets versions access latest --secret=shortener-api-key --project=swe455-urlshortener-252)"' >&2
  exit 1
fi

if python3 -c 'import sys' >/dev/null 2>&1; then
  PY="python3"
elif python -c 'import sys' >/dev/null 2>&1; then
  PY="python"
else
  echo "ERROR: python3 or python is required to parse JSON." >&2
  exit 1
fi

BODY_FILE="$(mktemp)"
HEADERS_FILE="$(mktemp)"
# Codes created during this run — populated as we go, deleted on exit.
CREATED_CODES=()

# ---------------------------------------------------------------------------
# Cleanup: runs on EXIT regardless of success/failure.
# Uses the Firestore REST API to delete smoke-test documents so they don't
# accumulate. Skipped silently if gcloud is not authenticated.
# ---------------------------------------------------------------------------
cleanup() {
  rm -f "$BODY_FILE" "$HEADERS_FILE"

  if [ "${#CREATED_CODES[@]}" -eq 0 ]; then
    return
  fi

  local token
  token="$(gcloud auth print-access-token 2>/dev/null)" || true
  if [ -z "${token:-}" ]; then
    echo "(note: gcloud not authenticated — skipping Firestore cleanup)"
    return
  fi

  local base="https://firestore.googleapis.com/v1/projects/${GCP_PROJECT}/databases/(default)/documents/urls"
  for code in "${CREATED_CODES[@]}"; do
    if curl -sS -o /dev/null -w '%{http_code}' -X DELETE \
        "${base}/${code}" \
        -H "Authorization: Bearer ${token}" | grep -qE '^2'; then
      echo "    -> cleaned up Firestore doc ${code}"
    fi
  done
}
trap cleanup EXIT

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

# ---------------------------------------------------------------------------
# Helper: POST long_url to a shortener endpoint, return the code.
# Usage: post_url <label> <url> [extra_curl_args...]
# ---------------------------------------------------------------------------
post_url() {
  local label="$1"
  local endpoint="$2"
  shift 2

  echo "==> POST ${endpoint}/api/urls  [${label}]"
  local status
  status="$(curl -sS -o "$BODY_FILE" -w '%{http_code}' \
    -X POST "${endpoint}/api/urls" \
    -H 'Content-Type: application/json' \
    -H "X-API-Key: ${API_KEY}" \
    -d "{\"long_url\":\"${TEST_LONG_URL}\"}" \
    "$@")"

  if [ "$status" != "201" ]; then
    echo "Response body:" >&2
    cat "$BODY_FILE" >&2 || true
    echo >&2
    fail "POST returned HTTP ${status}, expected 201"
  fi

  local code
  code="$("$PY" -c "
import json, sys
try:
    data = json.load(open(sys.argv[1]))
    print(data.get('code', ''))
except Exception:
    pass
" "$BODY_FILE")"

  if [ -z "$code" ]; then
    echo "Response body:" >&2
    cat "$BODY_FILE" >&2
    echo >&2
    fail "Could not parse 'code' from POST response"
  fi

  CREATED_CODES+=("$code")
  echo "    -> code=${code}"
  printf '%s' "$code"
}

# ---------------------------------------------------------------------------
# Helper: GET /{code} from the redirect service, assert 302 + Location.
# ---------------------------------------------------------------------------
assert_redirect() {
  local label="$1"
  local code="$2"

  echo "==> GET ${REDIRECT_URL}/${code}  [${label}, expect 302, no -L]"
  local status
  status="$(curl -sS -o /dev/null -D "$HEADERS_FILE" -w '%{http_code}' \
    "${REDIRECT_URL}/${code}")"

  if [ "$status" != "302" ]; then
    echo "Response headers:" >&2
    cat "$HEADERS_FILE" >&2 || true
    fail "GET returned HTTP ${status}, expected 302"
  fi

  local location
  location="$(grep -i '^location:' "$HEADERS_FILE" | head -1 \
    | sed -E 's/^[Ll]ocation:[[:space:]]*//' | tr -d '\r\n')"

  if [ -z "$location" ]; then
    echo "Response headers:" >&2
    cat "$HEADERS_FILE" >&2
    fail "No Location header in 302 response"
  fi

  if [ "$location" != "$TEST_LONG_URL" ]; then
    fail "Location mismatch: got '${location}', expected '${TEST_LONG_URL}'"
  fi

  echo "    -> Location=${location}"
}

# ---------------------------------------------------------------------------
# Test 1: direct path (shortener service -> redirect service)
# ---------------------------------------------------------------------------
CODE="$(post_url "direct" "$SHORTENER_URL")"
assert_redirect "direct" "$CODE"
echo "PASS: direct path (201 -> 302 -> Location matches)"

echo ""

# ---------------------------------------------------------------------------
# Test 2: gateway path (API Gateway -> shortener -> redirect service)
# ---------------------------------------------------------------------------
GW_CODE="$(post_url "gateway" "$GATEWAY_URL")"
assert_redirect "gateway" "$GW_CODE"
echo "PASS: gateway path (201 -> 302 -> Location matches)"

echo ""
echo "ALL TESTS PASSED"
