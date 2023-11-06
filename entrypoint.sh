#!/bin/bash

echo "Installing moodle"

echo "Fixing files and permissions"

chown -R www-data:www-data /var/www/html
find /var/www/html -iname "*.php" | xargs chmod +x

mkdir /var/www/moodledata
echo "placeholder" > /var/www/moodledata/placeholder
chown -R www-data:www-data /var/www/moodledata
chmod 777 /var/www/moodledata

echo "Setting up database"
: ${MOODLE_DB_TYPE:='mysqli'}

if [ "$MOODLE_DB_TYPE" = "mysqli" ] || [ "$MOODLE_DB_TYPE" = "mariadb" ]; then

  echo "Waiting for mysql to connect.."
  while ! mysqladmin ping -h"$MOODLE_DB_HOST" --silent; do
      sleep 1
  done

  echo "Setting up the database connection info"
: ${MOODLE_DB_USER:=${DB_ENV_MYSQL_USER:-root}}
: ${MOODLE_DB_NAME:=${DB_ENV_MYSQL_DATABASE:-'moodle'}}
: ${MOODLE_DB_PORT:=${DB_PORT_3306_TCP_PORT}}

  if [ "$MOODLE_DB_USER" = 'root' ]; then
: ${MOODLE_DB_PASSWORD:=$DB_ENV_MYSQL_ROOT_PASSWORD}
  else
: ${MOODLE_DB_PASSWORD:=$DB_ENV_MYSQL_PASSWORD}
  fi

  if [ -z "$MOODLE_DB_PASSWORD" ]; then
    echo >&2 'error: missing required MOODLE_DB_PASSWORD environment variable'
    echo >&2 '  Did you forget to -e MOODLE_DB_PASSWORD=... ?'
    echo >&2
    exit 1
  fi

else
  echo >&2 "This database type is not supported"
  echo >&2 "Did you forget to -e MOODLE_DB_TYPE='mysqli' ^OR^ -e MOODLE_DB_TYPE='mariadb' ?"
  exit 1
fi

echo "Installing moodle"
php /var/www/html/admin/cli/install_database.php \
          --adminemail=${MOODLE_ADMIN_EMAIL} \
          --adminuser=${MOODLE_ADMIN} \
          --adminpass=${MOODLE_ADMIN_PASSWORD} \
          --agree-license

exec "$@"
