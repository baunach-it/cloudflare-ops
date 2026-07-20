# cloudflare-ops

Docker-Image mit Wartungs-Skripten fuer Cloudflare Pages/Workers. Sub-Bereich
`cloudflare/` im Tenant `baunach`, Git-Org `Docker`, Registry `baunach/cloudflare-ops`.

## Struktur

- `entrypoint.sh` — Dispatcher, mappt Subcommand auf `commands/<name>.sh`
- `commands/` — ein Skript pro Subcommand
- `lib/common.sh` — gemeinsame Helper (`preflight`, Logging, JSON-Extraktion)

Neues Skript = neue Datei in `commands/`, executable, mit `--help`. Kein
Registrierungs-Schritt noetig, der Dispatcher findet sie ueber den Dateinamen.

## Konventionen

- Bash mit `set -euo pipefail`, Helper aus `lib/common.sh` sourcen.
- Destruktive Kommandos verlangen `--yes` und bieten `--dry-run`.
- Jede Schleife gegen die API braucht eine Abbruchbedingung (Fortschritts-Check
  + `--max-rounds`) — siehe [[concepts/cloudflare/pages-deployment-purge]].
- Wrangler-JSON-Felder sind versionsabhaengig (`Id` vs. `id`); Zugriffe mit
  Fallback-Kette in `lib/common.sh` kapseln, nicht inline im Kommando.
- Credentials ausschliesslich per Env (`--env-file`), nie ins Image.

## Build

Image-Build laeuft in CI (GitHub Actions nach gitea->GitHub-Mirror). Lokal:

```bash
docker build -t cloudflare-ops:dev .
docker run --rm cloudflare-ops:dev help
```

Image-Konventionen des Tenants: [[concepts/postgres/image-konventionen]].
