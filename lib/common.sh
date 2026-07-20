#!/usr/bin/env bash
# Shared helpers for all cloudflare-ops commands.
# Sourced by the scripts in commands/.

log() { printf '[cloudflare-ops] %s\n' "$*"; }
warn() { printf '[cloudflare-ops] WARN: %s\n' "$*" >&2; }
die() {
  printf '[cloudflare-ops] ERROR: %s\n' "$*" >&2
  exit 1
}

# Check the required env vars and verify the token against the API once.
#
# The verification is not cosmetic: the script from Cloudflare's docs spins
# forever on an invalid token, because every delete call fails, the deployment
# list never empties and the loop restarts endlessly. We abort right away.
preflight() {
  [ -n "${CLOUDFLARE_API_TOKEN:-}" ] ||
    die "CLOUDFLARE_API_TOKEN is not set (forgot --env-file?)"
  [ -n "${CLOUDFLARE_ACCOUNT_ID:-}" ] ||
    die "CLOUDFLARE_ACCOUNT_ID is not set (forgot --env-file?)"

  if ! wrangler whoami >/dev/null 2>&1; then
    die "Authentication failed. Check CLOUDFLARE_API_TOKEN / CLOUDFLARE_ACCOUNT_ID."
  fi
}

# ID of a Pages project's active production deployment.
#
# Wrangler's JSON field names have changed several times across major versions
# (Id vs. id, canonical_deployment vs. latest_deployment), hence the fallback
# chain. Returns an empty string if nothing can be determined — the caller then
# falls back to runtime detection.
pages_production_deployment_id() {
  local project="$1"
  wrangler pages project list --json 2>/dev/null |
    jq -r --arg p "$project" '
      (if type == "array" then . else .projects // [] end)
      | map(select((.name // .Name) == $p))
      | first
      | (.canonical_deployment // .latest_deployment // {})
      | (.id // .Id // empty)
    ' 2>/dev/null || true
}

# All deployment IDs of a Pages project, one per line.
pages_deployment_ids() {
  local project="$1"
  wrangler pages deployment list --project-name "$project" --json |
    jq -r '(if type == "array" then . else .deployments // [] end)[] | (.Id // .id // empty)'
}
