# Imagem simples para estudo de CI/CD — não otimizada para produção.
FROM node:20-alpine

WORKDIR /app

# Copia primeiro só os manifestos de dependências para aproveitar o cache de layers.
COPY package.json package-lock.json ./
RUN npm ci --omit=dev --ignore-scripts

COPY server.js ./

# Usuário não-root já vem definido na imagem node:alpine.
USER node

ENV PORT=3000
EXPOSE 3000

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s \
  CMD node -e "fetch('http://localhost:'+(process.env.PORT||3000)+'/health').then(r=>process.exit(r.ok?0:1)).catch(()=>process.exit(1))"

CMD ["node", "server.js"]
