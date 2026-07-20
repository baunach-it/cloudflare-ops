#!/usr/bin/env bash
set -euo pipefail
# shellcheck source=../lib/common.sh
. /usr/local/lib/cloudflare-ops/lib/common.sh

usage() {
  cat <<'EOF'
worker-delete — delete a Worker and its versions

Unlike Pages, Workers have NO deployment limit and no way to delete individual
versions or deployments (`wrangler versions delete` and `wrangler deployments
delete` do not exist). `wrangler delete` removes the Worker in one go — this
command is only a thin wrapper so that cleaning up Pages and Workers shares one
auth source.

Usage:
  worker-delete --name <worker> --yes [options]

Options:
  --name <worker>   Worker name (required)
  --yes             Confirmation (required, destructive)
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
      NAME="${2:?--name needs a value}"
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
    *) die "unknown option '$1' (see --help)" ;;
  esac
done

[ -n "$NAME" ] || {
  usage >&2
  die "--name is required"
}

if [ "$CONFIRM" != 1 ] && [ "$DRY_RUN" != 1 ]; then
  die "--yes is missing. Deleting Worker '${NAME}' cannot be undone."
fi

preflight

if [ "$DRY_RUN" = 1 ]; then
  exec wrangler delete --name "$NAME" --dry-run
fi

exec wrangler delete --name "$NAME"
