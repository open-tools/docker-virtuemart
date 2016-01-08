#!/bin/bash

set -e

if [[ ! -e "/etc/opentools-docker-configured" ]]; then
	# This docker container has not been configured yet, use the env variables 
	# to set up the MYSQL server or linked container

	# check if a MYSQL container is linked:
	if [ -n "$MYSQL_PORT_3306_TCP" ]; then
		if [ -z "$JOOMLA_DB_HOST" ]; then
			JOOMLA_DB_HOST='mysql'
		else
			echo >&2 "warning: both JOOMLA_DB_HOST and MYSQL_PORT_3306_TCP found"
			echo >&2 "  Connecting to JOOMLA_DB_HOST ($JOOMLA_DB_HOST)"
			echo >&2 "  instead of the linked mysql container"
		fi
	fi
	
	# If the DB user is 'root' and no DB password is given, then use the MySQL root password env var
	: ${JOOMLA_DB_USER:=root}
	if [ "$JOOMLA_DB_USER" = 'root' ]; then
			: ${JOOMLA_DB_PASSWORD:=$MYSQL_ENV_MYSQL_ROOT_PASSWORD}
	fi
	
	# Check for local MySQL installation:
	if [ -z "$JOOMLA_DB_HOST" ]; then
		# No linked container and no explicit DB host => local MySQL installation
		echo >&2 "Neither linked database container nor mysql dabase server host given. "
		echo >&2 "   Assuming local installation. An instance of the MySQL server will be installed locally."
		MYSQL_LOCAL=1
		JOOMLA_DB_HOST="127.0.0.1"
		if [ -z "${JOOMLA_DB_PASSWORD}" ]; then
			JOOMLA_DB_PASSWORD='root'
			echo >&2 "No MySQL root password given. Assuming password 'root'."
		fi
		echo >&2 "   Root password is ${JOOMLA_DB_PASSWORD}."
		
		# Temporarily start the mysql daemon to set up the database and shut it 
		# down again (supervisord will start it at the very end)
		echo "Starting temporary local MySQL server to set up the database..."
		/usr/bin/mysqld_safe > /dev/null 2>&1 &
		timeout=30
		echo -n "Waiting for database server to accept connections"
		while ! /usr/bin/mysqladmin --user=root --password=root status > /dev/null 2>&1; do
			timeout=$(($timeout-1))
			if [ $timeout -eq 0 ]; then
				echo -e "\n Unable to connecto the database server. Aborting..."
				exit 1
			fi
			echo -n "."
			sleep 1
		done
		echo
		mysqladmin --password=root password "${JOOMLA_DB_PASSWORD}"
		
		# enable mysqld in the supervisor config
		cp /etc/supervisor/conf.d/mysql.conf.save /etc/supervisor/conf.d/mysql.conf
	fi

	
	# Now set up the Database for Joomla/VirtueMart:
	: ${JOOMLA_DB_NAME:=virtuemart}

	if [ -z "$JOOMLA_DB_PASSWORD" ]; then
		echo >&2 "error: missing required JOOMLA_DB_PASSWORD environment variable"
		echo >&2 "  Did you forget to -e JOOMLA_DB_PASSWORD=... or link to a container?"
		echo >&2
		echo >&2 "  (Also of interest might be JOOMLA_DB_USER and JOOMLA_DB_NAME.)"
		exit 1
	fi
	# Ensure the MySQL Database is created
	php /makedb.php "$JOOMLA_DB_HOST" "$JOOMLA_DB_USER" "$JOOMLA_DB_PASSWORD" "$JOOMLA_DB_NAME"


	# Now set up the Joomla/VirtueMart installation files in apache's directory:
	if ! [ -e index.php -a -e libraries/cms/version/version.php ]; then
		echo >&2 "Virtuemart/Joomla not found in $(pwd) - copying now..."

		if [ "$(ls -A)" ]; then
			echo >&2 "WARNING: $(pwd) is not empty - press Ctrl+C now if this is an error!"
			( set -x; ls -A; sleep 10 )
		fi

		tar cf - --one-file-system -C /usr/src/virtuemart . | tar xf -
		
		# Some versions of the full installer hae an additional subdir in the ZIP file.
		# Search for joomla.xml and mv everything from that directory to the webroot
		if [ ! -e joomla.xml ]; then
			for jmanifest in */joomla.xml; do 
				jdir=$(dirname $jmanifest)
				echo
				mv $jdir/** .
				rm -rf $jdir
			done
		fi

		if [ -e htaccess.txt -a ! -e .htaccess ]; then
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

	if [ "$MYSQL_LOCAL" = "1" ]; then
		# Local installation, so shut down MySQL again, will later be started through supervisord
		echo "Shutting down temporary MySQL instance ..."
		/usr/bin/mysqladmin --user=root --password="${JOOMLA_DB_PASSWORD}" shutdown
	fi

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
	
	# create the file to indicate this container has been configured:
	touch /etc/opentools-docker-configured
fi

exec "$@"
