# Simple image for CI/CD study — not optimized for production.
FROM node:20-alpine

WORKDIR /app

# Copy dependency manifests first to leverage layer caching.
COPY package.json package-lock.json ./
# --ignore-scripts is deliberate supply-chain hardening (skips dependency lifecycle scripts, e.g. postinstall).
RUN npm ci --omit=dev --ignore-scripts

COPY server.js ./

# Non-root user is already set up in the node:alpine image.
USER node

ENV PORT=3000
EXPOSE 3000

# Only used by local `docker run` - under Kubernetes, k8s/deployment.yaml's own probes are what's actually checked.
HEALTHCHECK --interval=30s --timeout=3s --start-period=5s \
  CMD node -e "fetch('http://localhost:'+(process.env.PORT||3000)+'/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

CMD ["node", "server.js"]
