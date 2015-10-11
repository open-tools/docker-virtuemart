#!/bin/bash

set -e

if [[ "$1" == apache2* ]]; then
        if [ -n "$MYSQL_PORT_3306_TCP" ]; then
                if [ -z "$VM_DB_HOST" ]; then
                        VM_DB_HOST='mysql'
                else
                        echo >&2 "warning: both VM_DB_HOST and MYSQL_PORT_3306_TCP found"
                        echo >&2 "  Connecting to VM_DB_HOST ($VM_DB_HOST)"
                        echo >&2 "  instead of the linked mysql container"
                fi
        fi

        if [ -z "$VM_DB_HOST" ]; then
                echo >&2 "error: missing VM_DB_HOST and MYSQL_PORT_3306_TCP environment variables"
                echo >&2 "  Did you forget to --link some_mysql_container:mysql or set an external db"
                echo >&2 "  with -e VM_DB_HOST=hostname:port?"
                exit 1
        fi

        # If the DB user is 'root' then use the MySQL root password env var
        : ${VM_DB_USER:=root}
        if [ "$VM_DB_USER" = 'root' ]; then
                : ${VM_DB_PASSWORD:=$MYSQL_ENV_MYSQL_ROOT_PASSWORD}
        fi
        : ${VM_DB_NAME:=j2vm2}

        if [ -z "$VM_DB_PASSWORD" ]; then
                echo >&2 "error: missing required VM_DB_PASSWORD environment variable"
                echo >&2 "  Did you forget to -e VM_DB_PASSWORD=... ?"
                echo >&2
                echo >&2 "  (Also of interest might be VM_DB_USER and VM_DB_NAME.)"
                exit 1
        fi

        if ! [ -e index.php -a -e libraries/cms/version/version.php ]; then
                echo >&2 "Virtuemart/Joomla not found in $(pwd) - copying now..."

                if [ "$(ls -A)" ]; then
                        echo >&2 "WARNING: $(pwd) is not empty - press Ctrl+C now if this is an error!"
                        ( set -x; ls -A; sleep 10 )
                fi

                tar cf - --one-file-system -C /usr/src/virtuemart . | tar xf -

                if [ ! -e .htaccess ]; then
                        # NOTE: The "Indexes" option is disabled in the php:apache base image so remove it as we enable .htaccess
                        sed -r 's/^(Options -Indexes.*)$/#\1/' htaccess.txt > .htaccess
                        chown www-data:www-data .htaccess
                fi

                echo >&2 "Complete! Virtuemart has been successfully copied to $(pwd)"
        fi

        # Ensure the MySQL Database is created
        php /makedb.php "$VM_DB_HOST" "$VM_DB_USER" "$VM_DB_PASSWORD" "$VM_DB_NAME"

        echo >&2 "========================================================================"
        echo >&2
        echo >&2 "This server is now configured to run Joomla!"
        echo >&2 "You will need the following database information to install Joomla:"
        echo >&2 "Host Name: $VM_DB_HOST"
        echo >&2 "Database Name: $VM_DB_NAME"
        echo >&2 "Database Username: $VM_DB_USER"
        echo >&2 "Database Password: $VM_DB_PASSWORD"
        echo >&2
        echo >&2 "========================================================================"
fi

exec "$@"
