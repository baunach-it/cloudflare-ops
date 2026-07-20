# Docker Image für Cloudflare-Wartungsaufgaben

Sammel-Image für wiederkehrende Cloudflare-Aufräumarbeiten, die über die UI
nicht (mehr) gehen. Ein Image, mehrere Subcommands — neue Skripte kommen als
weitere Datei unter `commands/` dazu, ohne neues Repo/CI/Registry-Setup.

[Dockerfile](https://github.com/baunach-it/cloudflare-ops/blob/main/Dockerfile)

## Hintergrund

Cloudflare **Pages**-Projekte mit vielen Deployments lassen sich weder im
Dashboard noch per API in einem Rutsch löschen — die Deployments müssen vorher
einzeln weg
([Known Issue](https://developers.cloudflare.com/pages/platform/known-issues/#delete-a-project-with-a-high-amount-of-deployments)).

Für **Workers** gilt das nicht: dort gibt es weder ein Deployment-Limit noch
eine Einzel-Löschung von Versionen (`wrangler versions delete` existiert nicht).
`wrangler delete` räumt den Worker komplett ab. Der Subcommand `worker-delete`
ist deshalb nur ein dünner Wrapper für dieselbe Auth-Quelle.

## Usage

`.env` an der gewünschten Stelle anlegen (siehe `.env.example`):

```bash
CLOUDFLARE_API_TOKEN=...
CLOUDFLARE_ACCOUNT_ID=...
```

Der Token braucht die Permissions **Account → Cloudflare Pages → Edit** (und für
`worker-delete` zusätzlich **Account → Workers Scripts → Edit**).

```bash
# Alle Kommandos
docker run --rm baunach/cloudflare-ops:latest help

# Projekte auflisten
docker run --rm --env-file .env baunach/cloudflare-ops:latest pages-list-projects

# Erst schauen, was gelöscht würde
docker run --rm --env-file .env baunach/cloudflare-ops:latest \
  pages-purge-deployments --project mein-projekt --dry-run

# Deployments purgen (Production-Deployment bleibt stehen)
docker run --rm --env-file .env baunach/cloudflare-ops:latest \
  pages-purge-deployments --project mein-projekt

# Purge + Projekt löschen in einem Schritt
docker run --rm --env-file .env baunach/cloudflare-ops:latest \
  pages-delete-project --project mein-projekt --yes

# Worker löschen
docker run --rm --env-file .env baunach/cloudflare-ops:latest \
  worker-delete --name mein-worker --yes

# Beliebiges wrangler-Kommando durchreichen
docker run --rm --env-file .env baunach/cloudflare-ops:latest \
  wrangler pages deployment list --project-name mein-projekt
```

## Kommandos

| Kommando | Zweck |
|---|---|
| `pages-purge-deployments` | Löscht alle Deployments eines Pages-Projekts außer dem aktiven Production-Deployment |
| `pages-delete-project` | Purge + `wrangler pages project delete` (braucht `--yes`) |
| `pages-list-projects` | Pages-Projekte des Accounts auflisten |
| `worker-delete` | Worker samt Versionen löschen (braucht `--yes`) |
| `wrangler` | Rohes wrangler-Kommando |
| `help`, `version` | Hilfe / Wrangler-Version |

Jedes Kommando kennt `--help`.

## Unterschiede zum Skript aus der Cloudflare-Doku

Das Doku-Snippet ist als Copy-Paste-Einzeiler gedacht und hat zwei Fallen, die
hier behoben sind:

1. **Endlosschleife bei fehlerhaftem Token.** Scheitert jedes `delete`, leert
   sich die Liste nie und der Loop läuft ewig. Hier wird der Token vorab per
   `wrangler whoami` verifiziert, und eine Runde ohne jeden Fortschritt bricht
   ab (zusätzlich `--max-rounds` als harte Obergrenze).
2. **Production-Deployment nur über Fehlertext erkannt.** Hier wird die ID
   vorab aus `wrangler pages project list --json` gelesen; die Erkennung über
   den Fehlertext bleibt als Fallback erhalten.

Dazu `--dry-run` für alle destruktiven Kommandos.

## Image

- Registry: Docker Hub, Account `baunach` → `baunach/cloudflare-ops`
- Tags: `latest` und die gepinnte Wrangler-Version (z. B. `4.28.1`)
- Architektur: `linux/amd64`
- Wrangler ist ins Image gepinnt (kein `npx`-Download zur Laufzeit)
- Build via GitHub Actions: Push auf `main`, manueller Dispatch, wöchentlich
  Sonntag 03:00 UTC
