#!/bin/bash

set -e

if [[ "$1" == apache2* ]]; then
        if [ -n "$MYSQL_PORT_3306_TCP" ]; then
                if [ -z "$JOOMLA_DB_HOST" ]; then
                        JOOMLA_DB_HOST='mysql'
                else
                        echo >&2 "warning: both JOOMLA_DB_HOST and MYSQL_PORT_3306_TCP found"
                        echo >&2 "  Connecting to JOOMLA_DB_HOST ($JOOMLA_DB_HOST)"
                        echo >&2 "  instead of the linked mysql container"
                fi
        fi

        if [ -z "$JOOMLA_DB_HOST" ]; then
                echo >&2 "error: missing JOOMLA_DB_HOST and MYSQL_PORT_3306_TCP environment variables"
                echo >&2 "  Did you forget to --link some_mysql_container:mysql or set an external db"
                echo >&2 "  with -e JOOMLA_DB_HOST=hostname:port?"
                exit 1
        fi

        # If the DB user is 'root' then use the MySQL root password env var
        : ${JOOMLA_DB_USER:=root}
        if [ "$JOOMLA_DB_USER" = 'root' ]; then
                : ${JOOMLA_DB_PASSWORD:=$MYSQL_ENV_MYSQL_ROOT_PASSWORD}
        fi
        : ${JOOMLA_DB_NAME:=virtuemart}

        if [ -z "$JOOMLA_DB_PASSWORD" ]; then
                echo >&2 "error: missing required JOOMLA_DB_PASSWORD environment variable"
                echo >&2 "  Did you forget to -e JOOMLA_DB_PASSWORD=... ?"
                echo >&2
                echo >&2 "  (Also of interest might be JOOMLA_DB_USER and JOOMLA_DB_NAME.)"
                exit 1
        fi

        if ! [ -e index.php -a -e libraries/cms/version/version.php ]; then
                echo >&2 "Joomla not found in $(pwd) - copying now..."

                if [ "$(ls -A)" ]; then
                        echo >&2 "WARNING: $(pwd) is not empty - press Ctrl+C now if this is an error!"
                        ( set -x; ls -A; sleep 10 )
                fi

                tar cf - --one-file-system -C /usr/src/joomla . | tar xf -

                if [ ! -e .htaccess ]; then
                        # NOTE: The "Indexes" option is disabled in the php:apache base image so remove it as we enable .htaccess
                        sed -r 's/^(Options -Indexes.*)$/#\1/' htaccess.txt > .htaccess
                        chown www-data:www-data .htaccess
                fi

                echo >&2 "Complete! Joomla has been successfully copied to $(pwd)"
        fi

        # Ensure the MySQL Database is created
        php /makedb.php "$JOOMLA_DB_HOST" "$JOOMLA_DB_USER" "$JOOMLA_DB_PASSWORD" "$JOOMLA_DB_NAME"

        echo >&2 "========================================================================"
        echo >&2
        echo >&2 "This server is now configured to run Joomla!"
        echo >&2 "You will need the following database information to install Joomla:"
        echo >&2 "Host Name: $JOOMLA_DB_HOST"
        echo >&2 "Database Name: $JOOMLA_DB_NAME"
        echo >&2 "Database Username: $JOOMLA_DB_USER"
        echo >&2 "Database Password: $JOOMLA_DB_PASSWORD"
        echo >&2
        echo >&2 "========================================================================"
        
        
        # Now run the joomla Installer:
        
        : ${JOOMLA_ADMIN_USER:=admin}
        : ${JOOMLA_ADMIN_PASSWORD:=admin}
        : ${JOOMLA_ADMIN_EMAIL:=admin@example.com}
        : ${JOOMLA_SITE_NAME:=Joomla Installation}
        if [ -z "$JOOMLA_DB_PREFIX" ]; then
            DBPREFIX="--dbprefix=\"${JOOMLA_DB_PREFIX}_\""
        fi
        
        php ./installation/install.php --name "$JOOMLA_SITE_NAME" \
            --admin-user "$JOOMLA_ADMIN_USER" --admin-pass "$JOOMLA_ADMIN_PASSWORD" --admin-email "$JOOMLA_ADMIN_EMAIL" \
            --db-host "$JOOMLA_DB_HOST" --db-user "$JOOMLA_DB_USER" --db-pass "$JOOMLA_DB_PASSWORD" --db-name "$JOOMLA_DB_NAME" $DBPREFIX  && \
            rm -rf "./installation/"


        for p in /usr/src/virtuemart/*.zip; do
            php ./cli/install-joomla-extension.php --package=$p
        done
fi

exec "$@"
