#!/usr/bin/env bash
set -e

SHORTENER_URL="https://shortener-142958366034.us-central1.run.app"

echo "Testing shortener..."

# 1. Create short URL
RESPONSE=$(curl -s -X POST "$SHORTENER_URL/api/urls" \
  -H "Content-Type: application/json" \
  -H "X-API-Key: ${API_KEY:-test-key}" \
  -d '{"long_url":"https://example.com"}')

echo "Response: $RESPONSE"

# Extract code safely
CODE=$(echo "$RESPONSE" | python3 -c "
import sys, json
try:
    data = json.load(sys.stdin)
    print(data.get('code', ''))
except Exception:
    print('')
")

if [ -z "$CODE" ]; then
  echo "❌ Failed to create short URL"
  echo "$RESPONSE"
  exit 1
fi

SHORT_URL="$SHORTENER_URL/api/urls/$CODE"

echo "Testing redirect via: $SHORT_URL"

# 2. Follow redirect
RESULT=$(curl -s -o /dev/null -w "%{http_code}|%{redirect_url}" -L "$SHORT_URL")

HTTP_CODE=$(echo "$RESULT" | cut -d'|' -f1)
LOCATION=$(echo "$RESULT" | cut -d'|' -f2)

echo "HTTP_CODE=$HTTP_CODE"
echo "LOCATION=$LOCATION"

if [ "$HTTP_CODE" != "200" ] && [ "$HTTP_CODE" != "302" ]; then
  echo "❌ Smoke test failed"
  exit 1
fi

echo "Smoke test passed"