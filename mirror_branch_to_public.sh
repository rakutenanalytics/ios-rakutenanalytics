#!/usr/bin/env bash
set -euo pipefail

# Mirror a single branch from internal (ios-analytics) to public (ios-rakutenanalytics).
# Run this script from an ios-analytics clone.
# Excluded paths are removed from the mirrored branch (not copied from internal).

INTERNAL_REPO="${INTERNAL_REPO:-https://github.com/rakutenanalytics/ios-analytics.git}"
PUBLIC_REPO="${PUBLIC_REPO:-https://github.com/rakutenanalytics/ios-rakutenanalytics.git}"
INTERNAL_REMOTE="${INTERNAL_REMOTE:-origin}"
PUBLIC_REMOTE="${PUBLIC_REMOTE:-public}"
PUBLIC_BASE="${PUBLIC_BASE:-master}"

EXCLUDE_PATHS=(
  "ghe_sync.sh"
  ".github/CODEOWNERS"
)

BRANCH="${1:-}"
if [[ -z "$BRANCH" ]]; then
  echo "Usage: $0 <branch-name>"
  echo "Example: $0 feat/manual-viewable-impressions-tracking"
  exit 1
fi

# Ensure origin points to internal (ios-analytics)
ORIGIN_URL="$(git remote get-url "$INTERNAL_REMOTE")"
if [[ "$ORIGIN_URL" != *"ios-analytics"* ]] || [[ "$ORIGIN_URL" == *"ios-rakutenanalytics"* ]]; then
  echo "Error: run this script from an ios-analytics clone (internal)."
  echo "Current $INTERNAL_REMOTE remote: $ORIGIN_URL"
  exit 1
fi

if ! git remote get-url "$PUBLIC_REMOTE" &>/dev/null; then
  echo "Adding public remote '$PUBLIC_REMOTE' -> $PUBLIC_REPO"
  git remote add "$PUBLIC_REMOTE" "$PUBLIC_REPO"
else
  echo "Public remote '$PUBLIC_REMOTE' is already configured."
fi

echo "Fetching $BRANCH from internal (ios-analytics)..."
git fetch "$INTERNAL_REMOTE" "$BRANCH" --prune

echo "Fetching $PUBLIC_BASE and $BRANCH from public (ios-rakutenanalytics)..."
git fetch "$PUBLIC_REMOTE" "$PUBLIC_BASE" --prune
git fetch "$PUBLIC_REMOTE" "$BRANCH" --prune || true

echo "Checking out branch $BRANCH from internal..."
git checkout -B "$BRANCH" "$INTERNAL_REMOTE/$BRANCH"

echo "Removing paths excluded from internal mirror..."
for path in "${EXCLUDE_PATHS[@]}"; do
  git rm -rf "$path" 2>/dev/null || rm -rf "$path"
done

if ! git diff --cached --quiet || ! git diff --quiet; then
  git add -A
  git commit -m "chore: remove files excluded from internal mirror"
fi

echo "Pushing $BRANCH to public (ios-rakutenanalytics)..."
git push "$PUBLIC_REMOTE" "$BRANCH" --force-with-lease

echo "$BRANCH branch mirror complete."
