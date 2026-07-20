#!/usr/bin/env bash
# Gemeinsame Helper fuer alle cloudflare-ops Kommandos.
# Wird von den Skripten in commands/ gesourced.

log() { printf '[cloudflare-ops] %s\n' "$*"; }
warn() { printf '[cloudflare-ops] WARN: %s\n' "$*" >&2; }
die() {
  printf '[cloudflare-ops] ERROR: %s\n' "$*" >&2
  exit 1
}

# Pflicht-Env pruefen und Token einmalig gegen die API verifizieren.
#
# Das Verifizieren ist nicht kosmetisch: das Skript aus der Cloudflare-Doku
# laeuft bei ungueltigem Token in eine Endlosschleife, weil jeder delete-Aufruf
# scheitert, die Deployment-Liste sich nie leert und der Loop endlos neu startet.
# Wir brechen stattdessen sofort ab.
preflight() {
  [ -n "${CLOUDFLARE_API_TOKEN:-}" ] ||
    die "CLOUDFLARE_API_TOKEN ist nicht gesetzt (--env-file mitgeben?)"
  [ -n "${CLOUDFLARE_ACCOUNT_ID:-}" ] ||
    die "CLOUDFLARE_ACCOUNT_ID ist nicht gesetzt (--env-file mitgeben?)"

  if ! wrangler whoami >/dev/null 2>&1; then
    die "Authentifizierung fehlgeschlagen. CLOUDFLARE_API_TOKEN / CLOUDFLARE_ACCOUNT_ID pruefen."
  fi
}

# ID des aktiven Production-Deployments eines Pages-Projekts.
#
# Wranglers JSON-Feldnamen haben sich zwischen Major-Versionen mehrfach
# geaendert (Id vs. id, canonical_deployment vs. latest_deployment), darum die
# Fallback-Kette. Gibt leeren String zurueck, wenn nichts ermittelbar ist —
# der Aufrufer faellt dann auf die Laufzeit-Erkennung zurueck.
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

# Alle Deployment-IDs eines Pages-Projekts, eine pro Zeile.
pages_deployment_ids() {
  local project="$1"
  wrangler pages deployment list --project-name "$project" --json |
    jq -r '(if type == "array" then . else .deployments // [] end)[] | (.Id // .id // empty)'
}
