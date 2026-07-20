#!/usr/bin/env bash
set -euo pipefail

COMMAND_DIR="/usr/local/lib/cloudflare-ops/commands"

usage() {
  cat <<'EOF'
cloudflare-ops — maintenance scripts for Cloudflare Pages/Workers

Usage:
  docker run --rm --env-file .env baunach/cloudflare-ops <command> [options]

Commands:
  pages-purge-deployments   Delete every deployment of a Pages project
                            (except the active production deployment)
  pages-delete-project      Purge, then delete the project
  pages-list-projects       List the account's Pages projects
  worker-delete             Delete a Worker and its versions
  wrangler                  Pass through an arbitrary wrangler command
  version                   Print the wrangler version
  help                      This help

Environment (required):
  CLOUDFLARE_API_TOKEN      API token with Pages/Workers edit permissions
  CLOUDFLARE_ACCOUNT_ID     Account ID

Every command supports --help.
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
  echo "cloudflare-ops: unknown command '${cmd}'" >&2
  echo >&2
  usage >&2
  exit 2
fi

exec "$script" "$@"
