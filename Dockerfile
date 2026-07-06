FROM node:22-alpine AS build

WORKDIR /build
COPY index.html .

RUN npx --yes html-minifier-terser --collapse-whitespace --remove-comments --minify-css true \
      -o index.html index.html && \
    echo "BUILD_VERSION=$(date -u +%Y%m%d%H%M%S)" > /build/version.txt

FROM nginx:1.27-alpine AS production

COPY --from=build /build/index.html /usr/share/nginx/html/index.html
COPY --from=build /build/version.txt /usr/share/nginx/html/version.txt
COPY nginx/default.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

HEALTHCHECK --interval=10s --timeout=3s --retries=3 \
  CMD wget -q -O /dev/null http://localhost/ || exit 1
