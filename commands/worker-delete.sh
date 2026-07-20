#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=../lib/common.sh
. /usr/local/lib/cloudflare-ops/lib/common.sh

usage() {
  cat <<'EOF'
worker-delete — loescht einen Worker samt seiner Versionen

Anders als bei Pages gibt es bei Workers KEIN Deployment-Limit und keine
Einzel-Loeschung von Versionen/Deployments (`wrangler versions delete` bzw.
`wrangler deployments delete` existieren nicht). `wrangler delete` raeumt den
Worker in einem Rutsch ab — dieses Kommando ist nur ein duenner Wrapper, damit
Pages- und Workers-Aufraeumen ueber dieselbe Auth-Quelle laufen.

Usage:
  worker-delete --name <worker> --yes [options]

Options:
  --name <worker>   Worker-Name (Pflicht)
  --yes             Bestaetigung (Pflicht, da destruktiv)
  --dry-run         wrangler delete --dry-run
  --help
EOF
}

NAME=""
CONFIRM=0
DRY_RUN=0

while [ "$#" -gt 0 ]; do
  case "$1" in
    --name)
      NAME="${2:?--name braucht einen Wert}"
      shift 2
      ;;
    --yes)
      CONFIRM=1
      shift
      ;;
    --dry-run)
      DRY_RUN=1
      shift
      ;;
    --help | -h)
      usage
      exit 0
      ;;
    *) die "unbekannte Option '$1' (--help fuer Hilfe)" ;;
  esac
done

[ -n "$NAME" ] || {
  usage >&2
  die "--name ist Pflicht"
}

if [ "$CONFIRM" != 1 ] && [ "$DRY_RUN" != 1 ]; then
  die "--yes fehlt. Das Loeschen von Worker '${NAME}' ist nicht rueckgaengig zu machen."
fi

preflight

if [ "$DRY_RUN" = 1 ]; then
  exec wrangler delete --name "$NAME" --dry-run
fi

exec wrangler delete --name "$NAME"
