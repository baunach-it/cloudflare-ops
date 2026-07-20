#!/usr/bin/env bash
set -euo pipefail

COMMAND_DIR="/usr/local/lib/cloudflare-ops/commands"

usage() {
  cat <<'EOF'
cloudflare-ops — Wartungs-Skripte fuer Cloudflare Pages/Workers

Usage:
  docker run --rm --env-file .env baunach/cloudflare-ops <command> [options]

Commands:
  pages-purge-deployments   Loescht alle Deployments eines Pages-Projekts
                            (ausser dem aktiven Production-Deployment)
  pages-delete-project      Purge + anschliessendes Loeschen des Projekts
  pages-list-projects       Listet alle Pages-Projekte des Accounts
  worker-delete             Loescht einen Worker samt Versionen
  wrangler                  Beliebiges wrangler-Kommando durchreichen
  version                   Wrangler-Version ausgeben
  help                      Diese Hilfe

Environment (Pflicht):
  CLOUDFLARE_API_TOKEN      API-Token mit Pages-/Workers-Edit-Rechten
  CLOUDFLARE_ACCOUNT_ID     Account-ID

Jedes Kommando kennt --help.
EOF
}

cmd="${1:-help}"
[ "$#" -gt 0 ] && shift

case "$cmd" in
  help | -h | --help)
    usage
    exit 0
    ;;
  version | --version)
    exec wrangler --version
    ;;
  wrangler)
    exec wrangler "$@"
    ;;
esac

script="${COMMAND_DIR}/${cmd}.sh"
if [ ! -f "$script" ]; then
  echo "cloudflare-ops: unbekanntes Kommando '${cmd}'" >&2
  echo >&2
  usage >&2
  exit 2
fi

exec "$script" "$@"
