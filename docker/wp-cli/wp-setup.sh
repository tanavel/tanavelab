#!/usr/bin/env bash
set -eux

#================================================#
# Check running DB process.
#================================================#
wget -qO- https://raw.githubusercontent.com/eficode/wait-for/v2.1.2/wait-for \
| sh -s -- ${WORDPRESS_DB_HOST}:3306 -t 30

#================================================#
# Install WP core.
#================================================#
wp core install \
--url=${WORDPRESS_URL} \
--title=${WORDPRESS_TITLE} \
--admin_user=${WORDPRESS_ADMIN_USER_NAME} \
--admin_password=${WORDPRESS_ADMIN_USER_PASSWORD} \
--admin_email=${WORDPRESS_ADMIN_USER_MAIL_ADDRESS}

#================================================#
# Language setting.
#================================================#
wp language core install ${WORDPRESS_LANGUAGE} --activate

#================================================#
# Time setting.
#================================================#
wp option update timezone_string ${WORDPRESS_TZ}
wp option update date_format 'Y-m-d'
wp option update time_format 'H:i'
