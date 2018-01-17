#!/bin/bash

if [ $# -lt 2 ]; then
  echo 
  echo "    add-docker-vhost.sh DOMAINNAME PORT"
  echo
  echo "    Add a virtual host entry for DOMAINNAME.test that ProxyPasses to the given port on localhost."
  echo "    Needs admin privileges and thus should be run through sudo."
  exit
fi

NAME=$1
PORT=$2

sudo echo "<VirtualHost *:80>
	ServerName $NAME.test
	ServerAlias $NAME.lacolhost.com
	ServerAdmin $NAME@demo.open-tools.net

	ProxyPreserveHost on
	ProxyPass /        http://127.0.0.1:$PORT/
	ProxyPassReverse / http://127.0.0.1:$PORT/
</VirtualHost>

" >> /etc/apache2/sites-enabled/development.conf 

service apache2 restart

echo "Created virtual Host $NAME.test, proxied on port $PORT"
