#!/usr/bin/env bash
# Computes the next release version from the latest vX.Y.Z tag and the Conventional Commits since it.
#   `!` or a BREAKING CHANGE footer -> major, any feat -> minor, anything else but docs -> patch
#   `!` or `#` (e.g. `feat(api)#: ...`) -> no automatic deploy; `#` doesn't change the version
# Prints shell-evaluable lines: RELEASE=true|false, VERSION=X.Y.Z, BREAKING_CHANGE=true|false,
#   AUTO_DEPLOY=true|false
# Usage: eval "$(next-version.sh [ref])"   (ref defaults to HEAD; tags must be fetched)
set -euo pipefail

ref="${1:-HEAD}"
last_tag="$(git describe --tags --abbrev=0 --match 'v[0-9]*.[0-9]*.[0-9]*' "$ref" 2>/dev/null || true)"
range="${last_tag:+$last_tag..}$ref"
base="${last_tag#v}"
IFS=. read -r major minor patch <<<"${base:-0.0.0}"

subjects="$(git log --no-merges --pretty=%s "$range")"
if [ -z "$subjects" ] || ! grep -Eqv '^docs(\([^)]*\))?[!#]?:' <<<"$subjects"; then
  echo "RELEASE=false"
  echo "VERSION=${base:-0.0.0}"
  echo "BREAKING_CHANGE=false"
  echo "AUTO_DEPLOY=false"
  exit 0
fi

breaking=false
if grep -Eq '^[a-z]+(\([^)]*\))?!:' <<<"$subjects" ||
  git log --no-merges --pretty=%b "$range" | grep -Eq '^BREAKING[ -]CHANGE:'; then
  breaking=true
fi

auto_deploy=true
if [ "$breaking" = true ] || grep -Eq '^[a-z]+(\([^)]*\))?#:' <<<"$subjects"; then
  auto_deploy=false
fi

if [ "$breaking" = true ]; then
  major=$((major + 1)) minor=0 patch=0
elif grep -Eq '^feat(\([^)]*\))?[!#]?:' <<<"$subjects"; then
  minor=$((minor + 1)) patch=0
else
  patch=$((patch + 1))
fi

echo "RELEASE=true"
echo "VERSION=$major.$minor.$patch"
echo "BREAKING_CHANGE=$breaking"
echo "AUTO_DEPLOY=$auto_deploy"
