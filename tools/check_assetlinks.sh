#!/usr/bin/env bash
set -euo pipefail

ENDPOINT="https://androidnews.app/.well-known/assetlinks.json"
EXPECTED_PACKAGE="com.mucciologianfranco.android_news"
EXPECTED_FP="5C:E5:7E:6D:F3:78:A9:3F:B8:93:C5:F8:75:05:86:E9:A4:EA:17:3B:0B:34:F5:9C:C5:87:C8:2A:70:CF:8B:72"

echo "Checking $ENDPOINT"

# Fetch headers and body with status code (TLS must succeed)
HEADERS_FILE="/tmp/assetlinks.headers"
BODY_FILE="/tmp/assetlinks.json"

HTTP_CODE=$(curl -sS -D "$HEADERS_FILE" -o "$BODY_FILE" -w "%{http_code}" "$ENDPOINT" || true)
if [[ "$HTTP_CODE" != "200" ]]; then
  echo "Status: $HTTP_CODE"
  echo "FAIL: endpoint not 200"
  exit 2
fi

# Validate content-type
CONTENT_TYPE=$(awk 'BEGIN{IGNORECASE=1} /^content-type:/ {print $2}' "$HEADERS_FILE" | tr -d '\r')
if [[ -z "$CONTENT_TYPE" ]]; then
  echo "WARN: Content-Type header missing"
else
  echo "Content-Type: $CONTENT_TYPE"
  echo "$CONTENT_TYPE" | grep -qi "application/json" || {
    echo "FAIL: Content-Type not application/json"
    exit 6
  }
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq not found; installing jq..." >&2
  # Best effort for GH runners; skip on failure
  sudo apt-get update -y && sudo apt-get install -y jq || true
fi

PACKAGE=$(jq -r '.[0].target.package_name // empty' "$BODY_FILE" || true)
FINGERPRINT=$(jq -r '.[0].target.sha256_cert_fingerprints[0] // empty' "$BODY_FILE" || true)

if [[ -z "$PACKAGE" || -z "$FINGERPRINT" ]]; then
  echo "FAIL: JSON missing required fields"
  exit 3
fi

if [[ "$PACKAGE" != "$EXPECTED_PACKAGE" ]]; then
  echo "FAIL: package mismatch: $PACKAGE"
  exit 4
fi

if [[ "$FINGERPRINT" != "$EXPECTED_FP" ]]; then
  echo "FAIL: fingerprint mismatch: $FINGERPRINT"
  exit 5
fi

echo "OK: endpoint is valid with expected package, fingerprint and content-type"
exit 0
