FROM node:24.17.0-alpine3.24

WORKDIR /app

# This service has no runtime packages; omit package-manager dependency trees.
RUN rm -rf \
      /usr/local/lib/node_modules/npm \
      /usr/local/lib/node_modules/corepack \
      /opt/yarn-* \
    && rm -f \
      /usr/local/bin/npm \
      /usr/local/bin/npx \
      /usr/local/bin/corepack \
      /usr/local/bin/yarn \
      /usr/local/bin/yarnpkg

COPY --chown=10001:10001 app ./app

ENV NODE_ENV=production \
    PORT=8080

USER 10001:10001
EXPOSE 8080

HEALTHCHECK --interval=10s --timeout=2s --start-period=5s --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1:8080/health/live || exit 1

CMD ["node", "app/server.js"]
