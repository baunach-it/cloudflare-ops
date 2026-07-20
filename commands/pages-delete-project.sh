#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=../lib/common.sh
. /usr/local/lib/cloudflare-ops/lib/common.sh

usage() {
  cat <<'EOF'
pages-delete-project — purged alle Deployments und loescht danach das Projekt

Usage:
  pages-delete-project --project <name> --yes [options]

Options:
  --project, --project-name <name>   Pages-Projekt (Pflicht)
  --yes                              Bestaetigung (Pflicht, da destruktiv)
  --dry-run                          Nur zeigen, was passieren wuerde
  --max-rounds <n>                   an den Purge durchgereicht
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
      PROJECT="${2:?--project braucht einen Wert}"
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
      PURGE_ARGS+=(--max-rounds "${2:?--max-rounds braucht einen Wert}")
      shift 2
      ;;
    --help | -h)
      usage
      exit 0
      ;;
    *) die "unbekannte Option '$1' (--help fuer Hilfe)" ;;
  esac
done

[ -n "$PROJECT" ] || {
  usage >&2
  die "--project ist Pflicht"
}

if [ "$CONFIRM" != 1 ] && [ "$DRY_RUN" != 1 ]; then
  die "--yes fehlt. Das Loeschen von '${PROJECT}' ist nicht rueckgaengig zu machen."
fi

preflight

log "Schritt 1/2: Deployments von '${PROJECT}' purgen"
/usr/local/lib/cloudflare-ops/commands/pages-purge-deployments.sh \
  --project "$PROJECT" "${PURGE_ARGS[@]+"${PURGE_ARGS[@]}"}"

if [ "$DRY_RUN" = 1 ]; then
  log "--dry-run: Projekt '${PROJECT}' wird NICHT geloescht."
  exit 0
fi

log "Schritt 2/2: Projekt '${PROJECT}' loeschen"
wrangler pages project delete "$PROJECT" --yes
log "Projekt '${PROJECT}' geloescht."
