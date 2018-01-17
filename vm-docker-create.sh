#!/bin/bash

REPO=registry.open-tools.net/opentools/docker-virtuemart/j3vm3:latest

if [ $# -lt 3 ]; then
  echo "Usage: vm-docker-create.sh NAME PORT SITE_NAME"
  exit
fi

NAME=$1
PORT=$2
SITE=$3
SCRIPTDIR="$(dirname "$0")"

docker run -p $PORT:80 -d --name vm-$NAME -e JOOMLA_DB_USER=virtuemart -e JOOMLA_DB_PASSWORD=virtuemart -e JOOMLA_ADMIN_USER=opentools -e JOOMLA_ADMIN_PASSWORD=opentools -e JOOMLA_DB_NAME=vm_$NAME -e JOOMLA_SITE_NAME="${SITE}" -e JOOMLA_ADMIN_EMAIL="demo@demo.open-tools.net" $REPO

sudo $SCRIPTDIR/add-docker-vhost.sh vm-$NAME $PORT

echo "Please direct your browser to the newly installed site to finalize your Virtuemart installation:

    http://vm-$NAME.test/
    
    User: opentools
    Pass: opentools
    
    "
# docker exec -ti wc-$NAME /install-wc.sh "wc-${NAME}.test" "$SITE"
