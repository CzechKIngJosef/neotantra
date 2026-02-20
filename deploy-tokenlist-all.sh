#!/usr/bin/env bash
set -euo pipefail

SOURCE_URL="https://btj.neotantra.cz/tokenlist.json"
PUBLISH_DIR="${PUBLISH_DIR:-public}"
TOKEN_PATH="${TOKEN_PATH:-$PUBLISH_DIR/tokenlist.json}"
BRANCH="${BRANCH:-main}"

# Volitelné (pokud nechceš, nech prázdné)
NETLIFY_SITE_ID="${NETLIFY_SITE_ID:-}"
VERCEL_PROJECT="${VERCEL_PROJECT:-}"   # jen pokud chceš vynutit projekt (jinak podle linku)

echo "==> Kontrola: jsem v git repu?"
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "ERROR: Nejsi v git repozitari. Přejdi do repa (cd /cesta/k/repu) a spusť znovu."
  exit 1
fi

echo "==> 1) Stahuju tokenlist.json do: $TOKEN_PATH"
mkdir -p "$(dirname "$TOKEN_PATH")"
curl -fsSL "$SOURCE_URL" -o "$TOKEN_PATH"

echo "==> 2) GitHub Pages: commit + push"
git add "$TOKEN_PATH"
git commit -m "Update tokenlist.json" || echo "   (nic noveho na commit)"

# Kontrola origin remote
if ! git remote get-url origin >/dev/null 2>&1; then
  echo "ERROR: Git remote 'origin' neni nastaveny."
  echo "Nastav ho napr.:"
  echo "  git remote add origin git@github.com:OWNER/REPO.git"
  echo "a pak:"
  echo "  git push -u origin $BRANCH"
  exit 1
fi

git push origin "$BRANCH"

echo "==> 3) Netlify deploy --prod (pokud je netlify CLI)"
if command -v netlify >/dev/null 2>&1; then
  if [[ -n "$NETLIFY_SITE_ID" ]]; then
    netlify deploy --prod --dir "$PUBLISH_DIR" --site "$NETLIFY_SITE_ID"
  else
    netlify deploy --prod --dir "$PUBLISH_DIR"
  fi
else
  echo "   Netlify CLI neni nainstalovane -> preskakuju."
fi

echo "==> 4) Vercel deploy --prod (pokud je vercel CLI)"
if command -v vercel >/dev/null 2>&1; then
  if [[ -n "$VERCEL_PROJECT" ]]; then
    vercel deploy --prod --name "$VERCEL_PROJECT"
  else
    vercel deploy --prod
  fi
else
  echo "   Vercel CLI neni nainstalovane -> preskakuju."
fi

echo "✅ Hotovo."
