# Docker Image for Cloudflare Maintenance Tasks

Collection image for recurring Cloudflare cleanup work that cannot be done
through the dashboard. One image, multiple subcommands — new scripts are added
as another file under `commands/`, without setting up a new repo, CI pipeline or
registry entry.

[Dockerfile](https://github.com/baunach-it/cloudflare-ops/blob/main/Dockerfile)

## Background

Cloudflare **Pages** projects with many deployments cannot be deleted through
the dashboard or the API — the deployments have to be removed one by one first
([known issue](https://developers.cloudflare.com/pages/platform/known-issues/#delete-a-project-with-a-high-amount-of-deployments)).

This does not apply to **Workers**: there is neither a deployment limit nor a
way to delete individual versions (`wrangler versions delete` does not exist).
`wrangler delete` removes the Worker in one go. The `worker-delete` subcommand
is therefore only a thin wrapper, so both cases share one auth source.

## Usage

Create a `.env` wherever you need it (see `.env.example`):

```bash
CLOUDFLARE_API_TOKEN=...
CLOUDFLARE_ACCOUNT_ID=...
```

The token needs the permissions **Account → Cloudflare Pages → Edit** (and for
`worker-delete` additionally **Account → Workers Scripts → Edit**).

```bash
# All commands
docker run --rm baunach/cloudflare-ops:latest help

# List projects
docker run --rm --env-file .env baunach/cloudflare-ops:latest pages-list-projects

# See what would be deleted first
docker run --rm --env-file .env baunach/cloudflare-ops:latest \
  pages-purge-deployments --project my-project --dry-run

# Purge deployments (the production deployment is kept)
docker run --rm --env-file .env baunach/cloudflare-ops:latest \
  pages-purge-deployments --project my-project

# Purge and delete the project in one step
docker run --rm --env-file .env baunach/cloudflare-ops:latest \
  pages-delete-project --project my-project --yes

# Delete a Worker
docker run --rm --env-file .env baunach/cloudflare-ops:latest \
  worker-delete --name my-worker --yes

# Pass through an arbitrary wrangler command
docker run --rm --env-file .env baunach/cloudflare-ops:latest \
  wrangler pages deployment list --project-name my-project
```

## Commands

| Command | Purpose |
|---|---|
| `pages-purge-deployments` | Deletes every deployment of a Pages project except the active production deployment |
| `pages-delete-project` | Purge plus `wrangler pages project delete` (requires `--yes`) |
| `pages-list-projects` | Lists the account's Pages projects |
| `worker-delete` | Deletes a Worker and its versions (requires `--yes`) |
| `wrangler` | Raw wrangler command |
| `help`, `version` | Help / wrangler version |

Every command supports `--help`.

## Differences from the script in Cloudflare's docs

The documented snippet is meant as a copy-paste one-liner and has two pitfalls,
both fixed here:

1. **Infinite loop on a bad token.** If every `delete` fails, the deployment
   list never empties and the loop runs forever. Here the token is verified up
   front via `wrangler whoami`, and a round without any progress aborts
   (plus `--max-rounds` as a hard ceiling).
2. **Production deployment detected only via error text.** Here the ID is read
   from `wrangler pages project list --json` up front; detection via the error
   text remains as a fallback.

On top of that, every destructive command supports `--dry-run`.

## Image

- Registry: Docker Hub, account `baunach` → `baunach/cloudflare-ops`
- Tags: `latest` and the pinned wrangler version (e.g. `4.112.0`)
- Architecture: `linux/amd64`
- Wrangler is pinned into the image (no `npx` download at runtime)
- Built via GitHub Actions: push to `main`, manual dispatch, weekly on
  Sunday 03:00 UTC

## License

The Dockerfile and scripts in this repository are licensed under [MIT-0](LICENSE).

The image contains third-party software that is subject to its own licenses, including:
- Node.js from the official `node:22-alpine` base image: MIT (bundled components such as npm under their own licenses)
- Alpine Linux packages of the base image and those installed by the Dockerfile (`bash`, `jq`, `ca-certificates`): their respective licenses
- Wrangler, installed via npm during the build: MIT OR Apache-2.0 (its npm dependencies under their own licenses)
