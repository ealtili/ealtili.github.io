# syntax=docker/dockerfile:1

# ---------- Stage 1: source ----------
# Isolated stage so the runtime image never has build context / .git / tooling
# baked in, and so future build steps (minification, linting) have a clean
# place to hook in without touching the runtime stage.
FROM alpine:3.20 AS source
WORKDIR /src
COPY index.html ./index.html

# ---------- Stage 2: runtime ----------
# nginx-unprivileged runs as a non-root user out of the box and listens on
# 8080, avoiding the need to bind privileged port 80 as root.
FROM nginxinc/nginx-unprivileged:1.27-alpine AS runtime

LABEL org.opencontainers.image.title="erayweb" \
      org.opencontainers.image.description="Eray ALTILI portfolio - static site" \
      org.opencontainers.image.licenses="MIT"

COPY --chown=nginx:nginx --from=source /src/index.html /usr/share/nginx/html/index.html

USER nginx

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://127.0.0.1:8080/ >/dev/null 2>&1 || exit 1

CMD ["nginx", "-g", "daemon off;"]
