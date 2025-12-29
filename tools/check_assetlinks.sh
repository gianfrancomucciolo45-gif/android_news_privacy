#!/usr/bin/env bash
set -euo pipefail

ENDPOINT="https://androidnews.app/.well-known/assetlinks.json"
EXPECTED_PACKAGE="com.mucciologianfranco.android_news"
EXPECTED_FP="5C:E5:7E:6D:F3:78:A9:3F:B8:93:C5:F8:75:05:86:E9:A4:EA:17:3B:0B:34:F5:9C:C5:87:C8:2A:70:CF:8B:72"

echo "Checking $ENDPOINT"

# Fetch with status code
HTTP_CODE=$(curl -sS -o /tmp/assetlinks.json -w "%{http_code}" "$ENDPOINT" || true)
if [[ "$HTTP_CODE" != "200" ]]; then
  echo "Status: $HTTP_CODE"
  echo "FAIL: endpoint not 200"
  exit 2
fi

if ! command -v jq >/dev/null 2>&1; then
  echo "jq not found; installing jq..." >&2
  # Best effort for GH runners; skip on failure
  sudo apt-get update -y && sudo apt-get install -y jq || true
fi

PACKAGE=$(jq -r '.[0].target.package_name // empty' /tmp/assetlinks.json || true)
FINGERPRINT=$(jq -r '.[0].target.sha256_cert_fingerprints[0] // empty' /tmp/assetlinks.json || true)

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

echo "OK: endpoint is valid with expected package and fingerprint"
exit 0
