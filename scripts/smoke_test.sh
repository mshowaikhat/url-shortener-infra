#!/usr/bin/env bash
# Smoke test for the URL shortener system.
# POSTs a long URL to the shortener, captures the code, and verifies that
# the redirect service returns HTTP 302 with a matching Location header.
set -euo pipefail

SHORTENER_URL="${SHORTENER_URL:-https://shortener-142958366034.us-central1.run.app}"
REDIRECT_URL="${REDIRECT_URL:-https://redirect-142958366034.us-central1.run.app}"
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
trap 'rm -f "$BODY_FILE" "$HEADERS_FILE"' EXIT

fail() {
  echo "FAIL: $1" >&2
  exit 1
}

echo "==> POST $SHORTENER_URL/api/urls (long_url=$TEST_LONG_URL)"
POST_STATUS="$(curl -sS -o "$BODY_FILE" -w '%{http_code}' \
  -X POST "$SHORTENER_URL/api/urls" \
  -H 'Content-Type: application/json' \
  -H "X-API-Key: $API_KEY" \
  -d "{\"long_url\":\"$TEST_LONG_URL\"}")"

if [ "$POST_STATUS" != "201" ]; then
  echo "Response body:" >&2
  cat "$BODY_FILE" >&2 || true
  echo >&2
  fail "POST returned HTTP $POST_STATUS, expected 201"
fi

CODE="$("$PY" -c "
import json, sys
try:
    data = json.load(open(sys.argv[1]))
    print(data.get('code', ''))
except Exception:
    pass
" "$BODY_FILE")"

if [ -z "$CODE" ]; then
  echo "Response body:" >&2
  cat "$BODY_FILE" >&2
  echo >&2
  fail "Could not parse 'code' from POST response"
fi

echo "    -> code=$CODE"

echo "==> GET $REDIRECT_URL/$CODE (expect 302, no -L)"
GET_STATUS="$(curl -sS -o /dev/null -D "$HEADERS_FILE" -w '%{http_code}' \
  "$REDIRECT_URL/$CODE")"

if [ "$GET_STATUS" != "302" ]; then
  echo "Response headers:" >&2
  cat "$HEADERS_FILE" >&2 || true
  fail "GET returned HTTP $GET_STATUS, expected 302"
fi

LOCATION="$(grep -i '^location:' "$HEADERS_FILE" | head -1 | sed -E 's/^[Ll]ocation:[[:space:]]*//' | tr -d '\r\n')"

if [ -z "$LOCATION" ]; then
  echo "Response headers:" >&2
  cat "$HEADERS_FILE" >&2
  fail "No Location header in 302 response"
fi

if [ "$LOCATION" != "$TEST_LONG_URL" ]; then
  fail "Location mismatch: got '$LOCATION', expected '$TEST_LONG_URL'"
fi

echo "    -> Location=$LOCATION"
echo "PASS: 201 -> 302 -> Location matches"
