#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=../lib/common.sh
. /usr/local/lib/cloudflare-ops/lib/common.sh

usage() {
  cat <<'EOF'
pages-purge-deployments — loescht alle Deployments eines Pages-Projekts

Das aktive Production-Deployment bleibt erhalten (Cloudflare laesst es nicht
loeschen). Danach ist das Projekt ueber Dashboard bzw. pages-delete-project
loeschbar.

Usage:
  pages-purge-deployments --project <name> [options]

Options:
  --project, --project-name <name>   Pages-Projekt (Pflicht)
  --dry-run                          Nur zaehlen, nichts loeschen
  --max-rounds <n>                   Abbruch nach n Listen-Runden (Default: 200)
  --help
EOF
}

PROJECT=""
DRY_RUN=0
MAX_ROUNDS=200

while [ "$#" -gt 0 ]; do
  case "$1" in
    --project | --project-name)
      PROJECT="${2:?--project braucht einen Wert}"
      shift 2
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --max-rounds)
      MAX_ROUNDS="${2:?--max-rounds braucht einen Wert}"
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

preflight

prod_id="$(pages_production_deployment_id "$PROJECT")"
if [ -n "$prod_id" ]; then
  log "Production-Deployment: ${prod_id} (wird uebersprungen)"
else
  log "Production-Deployment nicht vorab ermittelbar — wird zur Laufzeit erkannt."
fi

deleted_total=0
round=0

while :; do
  round=$((round + 1))
  if [ "$round" -gt "$MAX_ROUNDS" ]; then
    die "Abbruch nach ${MAX_ROUNDS} Runden — Deployment-Liste leert sich nicht."
  fi

  ids="$(pages_deployment_ids "$PROJECT")"
  if [ -n "$prod_id" ]; then
    to_delete="$(printf '%s\n' "$ids" | grep -v -F -x -- "$prod_id" | grep . || true)"
  else
    to_delete="$(printf '%s\n' "$ids" | grep . || true)"
  fi

  if [ -z "$to_delete" ]; then
    log "Fertig. ${deleted_total} Deployment(s) geloescht. Verbleibend: ${prod_id:-keins}"
    break
  fi

  count="$(printf '%s\n' "$to_delete" | wc -l | tr -d ' ')"
  log "Runde ${round}: ${count} Deployment(s) zu loeschen"

  if [ "$DRY_RUN" = 1 ]; then
    log "--dry-run: nichts geloescht."
    break
  fi

  # Fortschritts-Wachhund: wenn eine ganze Runde weder etwas geloescht noch das
  # Production-Deployment identifiziert hat, dreht der Loop leer (Rechte fehlen,
  # API-Fehler, ...). Dann abbrechen statt endlos weiterzulaufen.
  progressed=0

  while IFS= read -r id; do
    output="$(wrangler pages deployment delete "$id" --project-name "$PROJECT" --force 2>&1 || true)"
    if printf '%s' "$output" | grep -q "Successfully deleted"; then
      deleted_total=$((deleted_total + 1))
      progressed=1
    elif printf '%s' "$output" | grep -q "active production deployment"; then
      log "Production-Deployment erkannt: ${id}"
      prod_id="$id"
      progressed=1
    else
      warn "Loeschen von ${id} fehlgeschlagen: $(printf '%s' "$output" | tr '\n' ' ')"
    fi
  done <<<"$to_delete"

  if [ "$progressed" = 0 ]; then
    die "Runde ${round} ohne Fortschritt — Abbruch. Token-Rechte (Pages:Edit) pruefen."
  fi
done
