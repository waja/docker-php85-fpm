# syntax = docker/dockerfile:1@sha256:b6afd42430b15f2d2a4c5a02b919e98a525b785b1aaff16747d2f623364e39b6
# requires DOCKER_BUILDKIT=1 set when running docker build
# checkov:skip=CKV_DOCKER_2: no healthcheck (yet)
# checkov:skip=CKV_DOCKER_3: no user (yet)
FROM php:8.5.2-fpm-alpine@sha256:506921c5cd6ad429ad3104c45f517ec3760a9389201378a81d482ffcc6c44905

ARG BUILD_DATE
ARG BUILD_VERSION
ARG VCS_URL
ARG VCS_REF
ARG VCS_BRANCH

# See http://label-schema.org/rc1/ and https://microbadger.com/labels
LABEL maintainer="Jan Wagner <waja@cyconet.org>" \
    org.label-schema.name="PHP 8.5 - FastCGI Process Manager" \
    org.label-schema.description="PHP-FPM 8.5 (with some more extensions installed)" \
    org.label-schema.vendor="Cyconet" \
    org.label-schema.schema-version="1.0" \
    org.label-schema.build-date="${BUILD_DATE:-unknown}" \
    org.label-schema.version="${BUILD_VERSION:-unknown}" \
    org.label-schema.vcs-url="${VCS_URL:-unknown}" \
    org.label-schema.vcs-ref="${VCS_REF:-unknown}" \
    org.label-schema.vcs-branch="${VCS_BRANCH:-unknown}" \
    org.opencontainers.image.source="https://github.com/waja/docker-php85-fpm"

ENV EXT_DEPS \
  freetype \
  libpng \
  libjpeg-turbo \
  libwebp \
  freetype-dev \
  libpng-dev \
  libjpeg-turbo-dev \
  libwebp-dev \
  libzip-dev \
  imagemagick-dev \
  libtool

# You can also use IMAGICK_SHA as IMAGICK_URL
#ENV IMAGICK_SHA=65e27f2bc02e7e8f1bf64e26e359e42a1331fca1
#ARG IMAGICK_URL=$IMAGICK_SHA
ENV IMAGICK_RELEASE=3.8.1
ARG IMAGICK_URL=refs/tags/$IMAGICK_RELEASE

WORKDIR /tmp/
# hadolint ignore=SC2086,DL3017,DL3018,DL3003
RUN set -xe; \
  apk --no-cache update && apk --no-cache upgrade \
  && apk add --no-cache ${EXT_DEPS} \
  && apk add --no-cache --virtual .build-deps ${PHPIZE_DEPS} \
  && docker-php-ext-configure bcmath \
  && docker-php-ext-configure exif \
  && docker-php-ext-configure gd \
    --with-freetype \
    --with-jpeg \
  && NPROC="$(grep -c ^processor /proc/cpuinfo 2>/dev/null || 1)" \
  && mkdir -p /tmp/imagick && curl -L -o /tmp/imagick.tar.gz https://github.com/Imagick/imagick/archive/${IMAGICK_URL}.tar.gz && tar --strip-components=1 -xf /tmp/imagick.tar.gz -C /tmp/imagick && cd /tmp/imagick && phpize && ./configure && make "-j${NPROC}" && make install \
  && docker-php-ext-install "-j${NPROC}" bcmath exif gd mysqli \
  && docker-php-ext-install "-j${NPROC}" zip \
  && docker-php-ext-enable bcmath exif gd imagick mysqli \
  && docker-php-ext-enable zip \
  && apk add --no-cache --virtual .imagick-runtime-deps imagemagick libgomp \
  # Cleanup build deps
  && apk del .build-deps \
  && rm -rf /tmp/* /var/cache/apk/*
WORKDIR /var/www/html/
