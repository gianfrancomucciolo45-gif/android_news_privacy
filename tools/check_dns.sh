#!/bin/bash
# DNS verification script for androidnews.app
# Checks if DNS records are correctly configured for GitHub Pages

set -e

DOMAIN="androidnews.app"
EXPECTED_IPS=(
  "185.199.108.153"
  "185.199.109.153"
  "185.199.110.153"
  "185.199.111.153"
)

echo "🔍 Checking DNS configuration for $DOMAIN"
echo "================================================"

# Check if dig is available
if ! command -v dig &> /dev/null; then
  echo "❌ 'dig' command not found. Install dnsutils: sudo apt install dnsutils"
  exit 1
fi

# Check A records
echo ""
echo "📋 A Records for $DOMAIN:"
ACTUAL_IPS=$(dig +short "$DOMAIN" @8.8.8.8 | sort)

if [[ -z "$ACTUAL_IPS" ]]; then
  echo "❌ No A records found for $DOMAIN"
  echo "   DNS might not be configured yet or still propagating."
  echo ""
  echo "💡 Expected A records:"
  for ip in "${EXPECTED_IPS[@]}"; do
    echo "   - $ip"
  done
  exit 2
fi

echo "$ACTUAL_IPS"

# Verify all expected IPs are present
MISSING=0
for expected_ip in "${EXPECTED_IPS[@]}"; do
  if ! echo "$ACTUAL_IPS" | grep -q "^$expected_ip$"; then
    echo "⚠️  Missing expected IP: $expected_ip"
    MISSING=1
  fi
done

if [[ $MISSING -eq 0 ]]; then
  echo "✅ All 4 GitHub Pages IPs configured correctly!"
else
  echo "❌ DNS configuration incomplete. Add missing IPs."
  exit 3
fi

# Check CNAME for www (optional)
echo ""
echo "📋 CNAME Record for www.$DOMAIN:"
WWW_TARGET=$(dig +short "www.$DOMAIN" @8.8.8.8 CNAME)

if [[ -z "$WWW_TARGET" ]]; then
  echo "⚠️  No CNAME found for www.$DOMAIN (optional but recommended)"
else
  echo "$WWW_TARGET"
  if echo "$WWW_TARGET" | grep -q "gianfrancomucciolo45-gif.github.io"; then
    echo "✅ www CNAME correctly configured!"
  else
    echo "⚠️  www CNAME points to unexpected target: $WWW_TARGET"
  fi
fi

# Check DNS propagation globally
echo ""
echo "🌍 Checking global DNS propagation..."
RESOLVERS=("8.8.8.8" "1.1.1.1" "208.67.222.222")
PROPAGATED=0

for resolver in "${RESOLVERS[@]}"; do
  IPS=$(dig +short "$DOMAIN" @"$resolver" 2>/dev/null | sort)
  if [[ "$IPS" == "$ACTUAL_IPS" ]]; then
    PROPAGATED=$((PROPAGATED + 1))
    echo "✅ $resolver: propagated"
  else
    echo "⏳ $resolver: not yet propagated or different IPs"
  fi
done

if [[ $PROPAGATED -eq ${#RESOLVERS[@]} ]]; then
  echo ""
  echo "🎉 DNS fully propagated across major resolvers!"
else
  echo ""
  echo "⏱️  DNS propagation in progress. May take 5-30 minutes."
fi

# Final summary
echo ""
echo "================================================"
echo "Summary:"
echo "  Domain: $DOMAIN"
echo "  A Records: $(echo "$ACTUAL_IPS" | wc -l)/4 configured"
echo "  Propagation: $PROPAGATED/${#RESOLVERS[@]} resolvers"
echo ""

if [[ $MISSING -eq 0 && $PROPAGATED -eq ${#RESOLVERS[@]} ]]; then
  echo "✅ DNS is ready! You can now:"
  echo "   1. Configure custom domain in GitHub Pages settings"
  echo "   2. Enable 'Enforce HTTPS' once certificate is issued"
  echo "   3. Verify endpoint: https://androidnews.app/.well-known/assetlinks.json"
  exit 0
else
  echo "⏳ DNS configuration incomplete or propagating."
  echo "   See docs/DNS_SETUP.md for detailed instructions."
  exit 4
fi
