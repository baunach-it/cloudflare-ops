#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=../lib/common.sh
. /usr/local/lib/cloudflare-ops/lib/common.sh

usage() {
  cat <<'EOF'
pages-purge-deployments — delete every deployment of a Pages project

The active production deployment is kept (Cloudflare refuses to delete it).
Afterwards the project can be deleted through the dashboard or via
pages-delete-project.

Usage:
  pages-purge-deployments --project <name> [options]

Options:
  --project, --project-name <name>   Pages project (required)
  --dry-run                          Only count, delete nothing
  --max-rounds <n>                   Abort after n list rounds (default: 200)
  --help
EOF
}

PROJECT=""
DRY_RUN=0
MAX_ROUNDS=200

while [ "$#" -gt 0 ]; do
  case "$1" in
    --project | --project-name)
      PROJECT="${2:?--project needs a value}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --max-rounds)
      MAX_ROUNDS="${2:?--max-rounds needs a value}"
      shift 2
      ;;
    --help | -h)
      usage
      exit 0
      ;;
    *) die "unknown option '$1' (see --help)" ;;
  esac
done

[ -n "$PROJECT" ] || {
  usage >&2
  die "--project is required"
}

preflight

prod_id="$(pages_production_deployment_id "$PROJECT")"
if [ -n "$prod_id" ]; then
  log "Production deployment: ${prod_id} (will be skipped)"
else
  log "Production deployment could not be determined up front — detecting at runtime."
fi

deleted_total=0
round=0

while :; do
  round=$((round + 1))
  if [ "$round" -gt "$MAX_ROUNDS" ]; then
    die "Aborting after ${MAX_ROUNDS} rounds — the deployment list is not emptying."
  fi

  ids="$(pages_deployment_ids "$PROJECT")"
  if [ -n "$prod_id" ]; then
    to_delete="$(printf '%s\n' "$ids" | grep -v -F -x -- "$prod_id" | grep . || true)"
  else
    to_delete="$(printf '%s\n' "$ids" | grep . || true)"
  fi

  if [ -z "$to_delete" ]; then
    log "Done. Deleted ${deleted_total} deployment(s). Remaining: ${prod_id:-none}"
    break
  fi

  count="$(printf '%s\n' "$to_delete" | wc -l | tr -d ' ')"
  log "Round ${round}: ${count} deployment(s) to delete"

  if [ "$DRY_RUN" = 1 ]; then
    log "--dry-run: nothing deleted."
    break
  fi

  # Progress watchdog: if a whole round neither deleted anything nor identified
  # the production deployment, the loop is spinning (missing permissions, API
  # errors, ...). Abort instead of running forever.
  progressed=0

  while IFS= read -r id; do
    output="$(wrangler pages deployment delete "$id" --project-name "$PROJECT" --force 2>&1 || true)"
    if printf '%s' "$output" | grep -q "Successfully deleted"; then
      deleted_total=$((deleted_total + 1))
      progressed=1
    elif printf '%s' "$output" | grep -q "active production deployment"; then
      log "Production deployment detected: ${id}"
      prod_id="$id"
      progressed=1
    else
      warn "Failed to delete ${id}: $(printf '%s' "$output" | tr '\n' ' ')"
    fi
  done <<<"$to_delete"

  if [ "$progressed" = 0 ]; then
    die "Round ${round} made no progress — aborting. Check the token permissions (Pages:Edit)."
  fi
done
