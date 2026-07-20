#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=../lib/common.sh
. /usr/local/lib/cloudflare-ops/lib/common.sh

usage() {
  cat <<'EOF'
pages-delete-project — purge all deployments, then delete the project

Usage:
  pages-delete-project --project <name> --yes [options]

Options:
  --project, --project-name <name>   Pages project (required)
  --yes                              Confirmation (required, destructive)
  --dry-run                          Only show what would happen
  --max-rounds <n>                   Passed through to the purge
  --help
EOF
}

PROJECT=""
CONFIRM=0
DRY_RUN=0
PURGE_ARGS=()

while [ "$#" -gt 0 ]; do
  case "$1" in
    --project | --project-name)
      PROJECT="${2:?--project needs a value}"
      shift 2
      ;;
    --yes)
      CONFIRM=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      PURGE_ARGS+=(--dry-run)
      shift
      ;;
    --max-rounds)
      PURGE_ARGS+=(--max-rounds "${2:?--max-rounds needs a value}")
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

if [ "$CONFIRM" != 1 ] && [ "$DRY_RUN" != 1 ]; then
  die "--yes is missing. Deleting '${PROJECT}' cannot be undone."
fi

preflight

log "Step 1/2: purging deployments of '${PROJECT}'"
/usr/local/lib/cloudflare-ops/commands/pages-purge-deployments.sh \
  --project "$PROJECT" "${PURGE_ARGS[@]+"${PURGE_ARGS[@]}"}"

if [ "$DRY_RUN" = 1 ]; then
  log "--dry-run: project '${PROJECT}' will NOT be deleted."
  exit 0
fi

log "Step 2/2: deleting project '${PROJECT}'"
wrangler pages project delete "$PROJECT" --yes
log "Project '${PROJECT}' deleted."
