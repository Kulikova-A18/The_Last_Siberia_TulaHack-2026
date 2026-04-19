FROM debian:bullseye-slim AS build-env

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        curl \
        git \
        unzip \
        xz-utils \
        libglu1-mesa \
        libstdc++6 \
        ca-certificates \
        && rm -rf /var/lib/apt/lists/*

RUN git clone --depth 1 -b stable https://github.com/flutter/flutter.git /opt/flutter

ENV PATH="/opt/flutter/bin:${PATH}"
ENV FLUTTER_ROOT="/opt/flutter"
ENV FLUTTER_ANALYTICS_REPORTING=false

RUN useradd -m -s /bin/bash flutteruser && \
    chown -R flutteruser:flutteruser /opt/flutter

USER flutteruser
WORKDIR /home/flutteruser

RUN flutter config --enable-web

COPY --chown=flutteruser:flutteruser . /app
WORKDIR /app

# Build arguments для конфигурации
ARG API_BASE_URL=http://localhost:8000
ARG WS_URL=ws://localhost:8000
ARG MOCK_ENABLED=false
ARG ENVIRONMENT=production

RUN echo "Building with configuration:" && \
    echo "  API_BASE_URL: ${API_BASE_URL}" && \
    echo "  WS_URL: ${WS_URL}" && \
    echo "  MOCK_ENABLED: ${MOCK_ENABLED}" && \
    echo "  ENVIRONMENT: ${ENVIRONMENT}"

RUN flutter pub get && \
    flutter build web --release \
        --dart-define=API_BASE_URL=${API_BASE_URL} \
        --dart-define=WS_URL=${WS_URL} \
        --dart-define=MOCK_ENABLED=${MOCK_ENABLED} \
        --dart-define=ENVIRONMENT=${ENVIRONMENT}

FROM nginx:1.21.1-alpine

COPY --from=build-env /app/build/web /usr/share/nginx/html
COPY --from=build-env /app/assets /usr/share/nginx/html/assets

# Создаем конфиг nginx с поддержкой SPA
RUN echo 'server { \
    listen 80; \
    root /usr/share/nginx/html; \
    index index.html; \
    location / { \
        try_files $uri $uri/ /index.html; \
    } \
    location /assets/ { \
        expires 1y; \
        add_header Cache-Control "public, immutable"; \
    } \
}' > /etc/nginx/conf.d/default.conf

RUN chmod -R 755 /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]