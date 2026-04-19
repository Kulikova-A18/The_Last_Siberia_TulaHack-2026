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
RUN flutter pub get && \
    flutter build web --release

FROM nginx:1.21.1-alpine

COPY --from=build-env /app/build/web /usr/share/nginx/html

COPY --from=build-env /app/assets /usr/share/nginx/html/assets

RUN chmod -R 755 /usr/share/nginx/html

RUN ls -la /usr/share/nginx/html/

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]