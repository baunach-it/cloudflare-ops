ARG BASE_IMAGE_VERSION=22-alpine

FROM node:${BASE_IMAGE_VERSION}

# Wrangler wird fest ins Image gepinnt — kein npx-Download zur Laufzeit,
# damit ein Run reproduzierbar ist und ohne npm-Registry-Zugriff funktioniert.
ARG WRANGLER_VERSION=latest

ENV CLOUDFLARE_API_TOKEN=""
ENV CLOUDFLARE_ACCOUNT_ID=""

# CI=true unterdrueckt Wranglers interaktive Prompts (Telemetrie, Update-Hinweis).
ENV CI=true
ENV WRANGLER_SEND_METRICS=false

RUN apk add --no-cache bash jq ca-certificates && \
    npm install -g "wrangler@${WRANGLER_VERSION}" && \
    npm cache clean --force

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY lib/ /usr/local/lib/cloudflare-ops/lib/
COPY commands/ /usr/local/lib/cloudflare-ops/commands/

RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/lib/cloudflare-ops/commands/*.sh

# Wrangler legt Cache/Config unter $HOME ab — Container laeuft unprivilegiert.
USER node
ENV HOME=/home/node

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["help"]
