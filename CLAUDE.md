# cloudflare-ops

Docker image with maintenance scripts for Cloudflare Pages/Workers. Sub-area
`cloudflare/` in tenant `baunach`, git org `Docker`, registry `baunach/cloudflare-ops`.

## Structure

- `entrypoint.sh` — dispatcher, maps a subcommand to `commands/<name>.sh`
- `commands/` — one script per subcommand
- `lib/common.sh` — shared helpers (`preflight`, logging, JSON extraction)

A new script means a new file in `commands/`, executable, with `--help`. No
registration step needed — the dispatcher finds it by filename.

## Conventions

- Bash with `set -euo pipefail`, source the helpers from `lib/common.sh`.
- Destructive commands require `--yes` and offer `--dry-run`.
- Every loop against the API needs a termination condition (progress check plus
  `--max-rounds`) — see [[concepts/cloudflare/pages-deployment-purge]].
- Wrangler JSON fields are version-dependent (`Id` vs. `id`); wrap accesses in a
  fallback chain in `lib/common.sh` rather than inline in the command.
- User-facing text (README, CLI help, log and error messages) is English.
- Credentials only via env (`--env-file`), never baked into the image.

## Build

The image build runs in CI (GitHub Actions after the gitea→GitHub mirror).
Locally:

```bash
docker build -t cloudflare-ops:dev .
docker run --rm cloudflare-ops:dev help
```

Tenant-wide image conventions: [[concepts/postgres/image-konventionen]].
