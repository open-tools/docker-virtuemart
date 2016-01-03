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

        # If the DB user is 'root' then use the MySQL root password env var
        : ${JOOMLA_DB_USER:=root}
        if [ "$JOOMLA_DB_USER" = 'root' ]; then
                : ${JOOMLA_DB_PASSWORD:=$MYSQL_ENV_MYSQL_ROOT_PASSWORD}
        fi
        if [ -z "$JOOMLA_DB_HOST" ]; then
			echo >&2 "Neither linked database container nor mysql dabase server host given. "
			echo >&2 "   Assuming local installation. An instance of the MySQL server will be installed locally."
			MYSQL_LOCAL=1
			JOOMLA_DB_HOST="127.0.0.1"
			if [ -z "${JOOMLA_DB_PASSWORD}" ]; then
				JOOMLA_DB_PASSWORD='root'
				echo >&2 "No MySQL root password given. Assuming password 'root'."
			fi
			echo >&2 "   Root password is ${JOOMLA_DB_PASSWORD}."
				
			export DEBIAN_FRONTEND=noninteractive

			echo "mysql-server-5.5 mysql-server/root_password password ${JOOMLA_DB_PASSWORD}" | debconf-set-selections
			echo "mysql-server-5.5 mysql-server/root_password_again password ${JOOMLA_DB_PASSWORD}" | debconf-set-selections
# 			echo 'phpmyadmin phpmyadmin/dbconfig-install boolean true' | debconf-set-selections
# 			echo 'phpmyadmin phpmyadmin/app-password-confirm password ${JOOMLA_DB_PASSWORD}' | debconf-set-selections
# 			echo 'phpmyadmin phpmyadmin/mysql/admin-pass password ${JOOMLA_DB_PASSWORD}' | debconf-set-selections
# 			echo 'phpmyadmin phpmyadmin/mysql/app-pass password ${JOOMLA_DB_PASSWORD}' | debconf-set-selections
# 			echo 'phpmyadmin phpmyadmin/reconfigure-webserver multiselect apache2' | debconf-set-selections

			dpkg -s mysql-server > /dev/null 2>&1 || ( apt-get -q update && apt-get -y -q install mysql-server && rm -rf /var/lib/apt/lists/* )
#                echo >&2 "error: missing JOOMLA_DB_HOST and MYSQL_PORT_3306_TCP environment variables"
#                echo >&2 "  Did you forget to --link some_mysql_container:mysql or set an external db"
#                echo >&2 "  with -e JOOMLA_DB_HOST=hostname:port?"
#                exit 1
        fi
        if [ -n "$MYSQL_LOCAL" ]; then
			echo >&2 "Starting MySQL daemon..."
			service mysql restart
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
                
                sed 's/default="localhost"/default="'$JOOMLA_DB_HOST'"/;
                     s/\(db_user.*\)$/\1 default="'$JOOMLA_DB_USER'"/;
                     s/\(db_pass.*\)$/\1 default="'$JOOMLA_DB_PASSWORD'"/;
                     s/\(db_name.*\)$/\1 default="'$JOOMLA_DB_NAME'"/' installation/models/forms/database.xml > installation/models/forms/database.xml.new
				mv installation/models/forms/database.xml.new installation/models/forms/database.xml

                echo >&2 "Complete! Virtuemart has been successfully copied to $(pwd)"
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
fi

exec "$@"
