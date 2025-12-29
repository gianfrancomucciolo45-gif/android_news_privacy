#!/usr/bin/env bash
set -euo pipefail

# This script sets SMTP_* GitHub Actions secrets using the GitHub CLI (gh).
# Prerequisites:
#  - Install GitHub CLI: https://cli.github.com/
#  - Run: gh auth login

REPO_SLUG=${REPO_SLUG:-}

if ! command -v gh >/dev/null 2>&1; then
  echo "ERROR: GitHub CLI (gh) non trovato. Installa da https://cli.github.com/" >&2
  exit 1
fi

if [[ -z "$REPO_SLUG" ]]; then
  echo "Inserisci owner/repo (es. gianfrancomucciolo45-gif/android_news_privacy):"
  read -r REPO_SLUG
fi

read -r -p "SMTP_HOST (es. smtp.mail.yahoo.com): " SMTP_HOST
read -r -p "SMTP_PORT (es. 465 o 587): " SMTP_PORT
read -r -p "SMTP_USERNAME (di solito l'email): " SMTP_USERNAME
read -r -s -p "SMTP_PASSWORD (app password consigliata): " SMTP_PASSWORD; echo
read -r -p "SMTP_FROM (mittente, es. gmucciolo85@yahoo.it): " SMTP_FROM

echo "\nImposto i secrets sul repo $REPO_SLUG..."

gh secret set SMTP_HOST --repo "$REPO_SLUG" --body "$SMTP_HOST"
gh secret set SMTP_PORT --repo "$REPO_SLUG" --body "$SMTP_PORT"
gh secret set SMTP_USERNAME --repo "$REPO_SLUG" --body "$SMTP_USERNAME"
gh secret set SMTP_PASSWORD --repo "$REPO_SLUG" --body "$SMTP_PASSWORD"
gh secret set SMTP_FROM --repo "$REPO_SLUG" --body "$SMTP_FROM"

echo "Fatto. Il workflow invierà email quando l'endpoint diventa OK."
