#!/usr/bin/env bash
set -u

#================================================#
# Load .env
#================================================#
if [ -f .env ]; then
  export $(grep -v '^#' .env | xargs)
fi

#================================================#
# Check connect DB process.
#================================================#
result=1
until [ ${result} -eq 0 ]; do
    echo "Connecting DB ..."
    nc -w 1 ${DB_HOST} 3306 > /dev/null 2>&1
    result=$?
    sleep 5
done
echo "Success connecting DB!!"

#================================================#
# Check composer install is finished.
#================================================#
until [ -e ./vendor/autoload.php ]; do
    echo "Check composer install is finished ..."
    sleep 5
done
echo "Success composer install!!"

#================================================#
# Install WP core.
#================================================#
wp core install \
--url=${WP_URL} \
--title=${WP_TITLE} \
--admin_user=${WP_ADMIN_USER_NAME} \
--admin_password=${WP_ADMIN_USER_PASSWORD} \
--admin_email=${WP_ADMIN_USER_MAIL_ADDRESS}

#================================================#
# Language setting.
# TODO: AWS環境では、翻訳ファイルはダウンロード済みの状態でbuildするから、必要なのはactivateだけかも
#================================================#
wp language core install ja --activate

#================================================#
# Time setting.
# TODO: 絶対固定なのでフックとか使って固定させる方がええんやろな
#================================================#
wp option update timezone_string 'Asia/Tokyo'
wp option update date_format 'Y-m-d'
wp option update time_format 'H:i'
