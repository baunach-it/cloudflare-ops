#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=../lib/common.sh
. /usr/local/lib/cloudflare-ops/lib/common.sh

usage() {
  cat <<'EOF'
pages-list-projects — listet die Pages-Projekte des Accounts

Usage:
  pages-list-projects [--json]

Options:
  --json     Rohes wrangler-JSON ausgeben
  --help
EOF
}

AS_JSON=0
while [ "$#" -gt 0 ]; do
  case "$1" in
    --json)
      AS_JSON=1
      shift
      ;;
    --help | -h)
      usage
      exit 0
      ;;
    *) die "unbekannte Option '$1' (--help fuer Hilfe)" ;;
  esac
done

preflight

if [ "$AS_JSON" = 1 ]; then
  exec wrangler pages project list --json
fi

exec wrangler pages project list
