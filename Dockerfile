ARG BASE_IMAGE_VERSION=22-alpine

FROM node:${BASE_IMAGE_VERSION}

# Wrangler is pinned into the image — no npx download at runtime, so a run is
# reproducible and works without access to the npm registry.
ARG WRANGLER_VERSION=latest

ENV CLOUDFLARE_API_TOKEN=""
ENV CLOUDFLARE_ACCOUNT_ID=""

# CI=true suppresses wrangler's interactive prompts (telemetry, update notice).
ENV CI=true
ENV WRANGLER_SEND_METRICS=false

RUN apk add --no-cache bash jq ca-certificates && \
    npm install -g "wrangler@${WRANGLER_VERSION}" && \
    npm cache clean --force

COPY entrypoint.sh /usr/local/bin/entrypoint.sh
COPY lib/ /usr/local/lib/cloudflare-ops/lib/
COPY commands/ /usr/local/lib/cloudflare-ops/commands/

RUN chmod +x /usr/local/bin/entrypoint.sh /usr/local/lib/cloudflare-ops/commands/*.sh

# The container runs unprivileged. WORKDIR matters: wrangler creates its cache
# relative to the current directory (./.wrangler/cache), so the default cwd of /
# — owned by root — makes every real command fail with a permission error.
USER node
ENV HOME=/home/node
WORKDIR /home/node

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["help"]
