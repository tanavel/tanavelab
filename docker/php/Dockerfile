FROM php:7.4-fpm

# persistent dependencies
RUN set -eux; \
  apt-get update; \
  apt-get install -y --no-install-recommends \
# Ghostscript is required for rendering PDF previews
    ghostscript \
  ; \
  rm -rf /var/lib/apt/lists/*

# install the PHP extensions we need (https://make.wordpress.org/hosting/handbook/handbook/server-environment/#php-extensions)
RUN set -ex; \
  \
  savedAptMark="$(apt-mark showmanual)"; \
  \
  apt-get update; \
  apt-get install -y --no-install-recommends \
    libfreetype6-dev \
    libjpeg-dev \
    libmagickwand-dev \
    libpng-dev \
    libwebp-dev \
    libzip-dev \
  ; \
  \
  docker-php-ext-configure gd \
    --with-freetype \
    --with-jpeg \
    --with-webp \
  ; \
  docker-php-ext-install -j "$(nproc)" \
    bcmath \
    exif \
    gd \
    mysqli \
    zip \
  ; \
# https://pecl.php.net/package/imagick
  pecl install imagick-3.6.0; \
  docker-php-ext-enable imagick; \
  rm -r /tmp/pear; \
  \
# some misbehaving extensions end up outputting to stdout 🙈 (https://github.com/docker-library/wordpress/issues/669#issuecomment-993945967)
  out="$(php -r 'exit(0);')"; \
  [ -z "$out" ]; \
  err="$(php -r 'exit(0);' 3>&1 1>&2 2>&3)"; \
  [ -z "$err" ]; \
  \
  extDir="$(php -r 'echo ini_get("extension_dir");')"; \
  [ -d "$extDir" ]; \
# reset apt-mark's "manual" list so that "purge --auto-remove" will remove all build dependencies
  apt-mark auto '.*' > /dev/null; \
  apt-mark manual $savedAptMark; \
  ldd "$extDir"/*.so \
    | awk '/=>/ { print $3 }' \
    | sort -u \
    | xargs -r dpkg-query -S \
    | cut -d: -f1 \
    | sort -u \
    | xargs -rt apt-mark manual; \
  \
  apt-get purge -y --auto-remove -o APT::AutoRemove::RecommendsImportant=false; \
  rm -rf /var/lib/apt/lists/*; \
  \
  ! { ldd "$extDir"/*.so | grep 'not found'; }; \
# check for output like "PHP Warning:  PHP Startup: Unable to load dynamic library 'foo' (tried: ...)
  err="$(php --version 3>&1 1>&2 2>&3)"; \
  [ -z "$err" ]

# setup wp-cli
ENV WP_CLI_ALLOW_ROOT=true

RUN set -eux; \
  apt-get update; \
  apt-get install -y --no-install-recommends \
    less \
    netcat \
  ; \
  curl -O https://raw.githubusercontent.com/wp-cli/builds/gh-pages/phar/wp-cli.phar; \
  chmod +x wp-cli.phar; \
  mv wp-cli.phar /usr/local/bin/wp

COPY ./docker/php/wp-install.sh /usr/local/bin/wp-install.sh

COPY ./src /var/www/tanavelab

COPY ./docker/php/php.ini /usr/local/etc/php/conf.d/php.ini

CMD ["php-fpm"]
