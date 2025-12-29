#!/bin/bash
# GitHub Pages Custom Domain Setup Helper
# This script provides step-by-step instructions to configure custom domain

set -e

REPO_OWNER="gianfrancomucciolo45-gif"
REPO_NAME="android_news_privacy"
CUSTOM_DOMAIN="androidnews.app"

echo "🔧 GitHub Pages Custom Domain Setup"
echo "===================================="
echo ""
echo "Repository: $REPO_OWNER/$REPO_NAME"
echo "Custom Domain: $CUSTOM_DOMAIN"
echo ""

# Check if CNAME file exists
if [[ ! -f "CNAME" ]]; then
  echo "❌ CNAME file not found in repository root!"
  echo "   Creating CNAME file..."
  echo "$CUSTOM_DOMAIN" > CNAME
  git add CNAME
  git commit -m "Add CNAME for custom domain"
  git push
  echo "✅ CNAME file created and pushed"
else
  CNAME_CONTENT=$(cat CNAME)
  if [[ "$CNAME_CONTENT" == "$CUSTOM_DOMAIN" ]]; then
    echo "✅ CNAME file exists with correct domain: $CUSTOM_DOMAIN"
  else
    echo "⚠️  CNAME file contains different domain: $CNAME_CONTENT"
    echo "   Expected: $CUSTOM_DOMAIN"
    read -p "Update CNAME? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
      echo "$CUSTOM_DOMAIN" > CNAME
      git add CNAME
      git commit -m "Update CNAME to $CUSTOM_DOMAIN"
      git push
      echo "✅ CNAME updated and pushed"
    fi
  fi
fi

echo ""
echo "📋 Next Steps - Manual Configuration Required:"
echo ""
echo "1️⃣  Configure DNS (if not done already):"
echo "   See docs/DNS_SETUP.md for detailed instructions"
echo "   Quick check: ./tools/check_dns.sh"
echo ""
echo "2️⃣  GitHub Pages Settings:"
echo "   a) Open: https://github.com/$REPO_OWNER/$REPO_NAME/settings/pages"
echo "   b) Under 'Custom domain', enter: $CUSTOM_DOMAIN"
echo "   c) Click 'Save'"
echo "   d) Wait for DNS verification (usually 1-5 minutes)"
echo ""
echo "3️⃣  Enable HTTPS:"
echo "   a) Once DNS is verified, GitHub will issue SSL certificate"
echo "   b) This takes 10-20 minutes typically"
echo "   c) When ready, check 'Enforce HTTPS' checkbox"
echo "   d) Click 'Save'"
echo ""
echo "4️⃣  Verify Endpoint:"
echo "   Run: ./tools/check_assetlinks.sh"
echo "   Expected: 200 OK with valid JSON"
echo ""
echo "5️⃣  Play Console:"
echo "   a) Go to: https://play.google.com/console"
echo "   b) App integrity → App links"
echo "   c) Find androidnews.app domain"
echo "   d) Click 'Ricontrolla la verifica'"
echo "   e) Wait for verification result"
echo ""

# Offer to open browser
read -p "📱 Open GitHub Pages settings in browser? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
  URL="https://github.com/$REPO_OWNER/$REPO_NAME/settings/pages"
  if command -v xdg-open &> /dev/null; then
    xdg-open "$URL"
  elif command -v open &> /dev/null; then
    open "$URL"
  else
    echo "Please open manually: $URL"
  fi
fi

echo ""
echo "✅ Setup helper completed!"
echo "   Monitor progress with: ./tools/check_dns.sh"
echo "   and: ./tools/check_assetlinks.sh"
