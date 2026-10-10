#!/usr/bin/env bash
# Sync album photos from a private Cloudflare R2 bucket into exampleSite/content/.
#
# The theme expects photo files next to each album's index.md (page resources).
# Credentials are never stored in this file or the repo — pass them via env vars,
# in CI they come from repository Actions secrets.
#
# Required env vars:
#   R2_ENDPOINT        e.g. https://<ACCOUNT_ID>.r2.cloudflarestorage.com
#   R2_BUCKET          e.g. album-photos
#   R2_ACCESS_KEY_ID
#   R2_SECRET_ACCESS_KEY
#
# Optional:
#   CONTENT_DIR        default: exampleSite/content
#
# If the R2 secrets are not set, the script exits successfully and does nothing,
# so the build keeps using any images already in the repository.

set -euo pipefail

missing=()
[[ -z "${R2_ENDPOINT:-}" ]] && missing+=(R2_ENDPOINT)
[[ -z "${R2_BUCKET:-}" ]] && missing+=(R2_BUCKET)
[[ -z "${R2_ACCESS_KEY_ID:-}" ]] && missing+=(R2_ACCESS_KEY_ID)
[[ -z "${R2_SECRET_ACCESS_KEY:-}" ]] && missing+=(R2_SECRET_ACCESS_KEY)

if [[ ${#missing[@]} -gt 0 ]]; then
  echo "R2 not configured (missing: ${missing[*]}); skipping image sync." >&2
  echo "Add these as GitHub Actions secrets to enable Cloudflare R2 sync." >&2
  exit 0
fi

command -v rclone >/dev/null 2>&1 || { echo "rclone is required on PATH" >&2; exit 1; }

# Drive rclone purely from env vars (no rclone.conf file, nothing written to disk).
export RCLONE_CONFIG_R2_TYPE=s3
export RCLONE_CONFIG_R2_PROVIDER=Cloudflare
export RCLONE_CONFIG_R2_ACCESS_KEY_ID="$R2_ACCESS_KEY_ID"
export RCLONE_CONFIG_R2_SECRET_ACCESS_KEY="$R2_SECRET_ACCESS_KEY"
export RCLONE_CONFIG_R2_ENDPOINT="$R2_ENDPOINT"
export RCLONE_CONFIG_R2_NO_CHECK_BUCKET=true

CONTENT_DIR="${CONTENT_DIR:-exampleSite/content}"
mkdir -p "$CONTENT_DIR"

rclone copy "r2:${R2_BUCKET}" "$CONTENT_DIR" \
  --create-empty-src-dirs \
  --transfers 16

echo "Images synced from R2 bucket '${R2_BUCKET}' into ${CONTENT_DIR}"