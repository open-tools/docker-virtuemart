# What is VirtueMart

Virtuemart is a full-feature e-Commerce suite, which relies on and needs to be installed inside Joomla. For further information see http://www.virtuemart.net/

# About this image and its requirements

This docker image provides the stock VirtueMart installation. There are tags for the full installer (which includes Joomla 2.5.28 and Virtuemart 3.x including sample products) and for a Joomla 3 installation (latest Joomla with Virtuemart 3.x, no sample products will be set up). 
Unless you configure the image differently, the MySQL database connection to the linked mysql contaner will be:
  - Database Host: mysql
  - Database User: root
  - Database Password: (the root password configured with the MYSQL_ROOT_PASSWORD env var when creating the mysql container)
  - Database: virtuemart

This image needs a mysql daemon set up (the database will be created by this image). Typically, you want to set up a mysql docker container and link it to this virtuemart container:

```console
$ docker run --name some-mysql -e MYSQL_ROOT_PASSWORD=my-secret-pw -d mysql:tag
```
where some-mysql is the name you want to assign to your container, my-secret-pw is the password to be set for the MySQL root user and tag is the tag specifying the MySQL version you want (e.g. 5.6).

This mysql container can then be linked to the virtuemart container as described below.

# Which tags / variants are available for this image?

  - `opentools/docker-virtuemart:fullinstall` ... The stock fullinstaller provided by the VirtueMart Team (Joomla 2.5.28, Virtuemart 3.0.10). Automatic installation not possible, but the joomla installer will be run when you point your webbrowser to this container (see below). 
  - `opentools/docker-virtuemart:j3vm3` ... Joomla 3 installation with Virtuemart 3.x. Automatic installation of Joomla and VirtueMart is attempted, admin username, password, email etc. are passed as env variables (see below)
# How to use this image


```console
$ docker run --name some-virtuemart --link some-mysql:mysql -d opentools/virtuemart:tag
```
where `tag` is either `fullinstall` (for the VM 3.0.10 full installer on Joomla 2.5.28, including sample data) or `j3vm3` for an automatic installation of VM 3.0.10 on Joomla 3.x (but no sample data).

The following environment variables are also honored for configuring your Joomla instance:

-	`-e JOOMLA_DB_HOST=...` (defaults to the IP and port of the linked `mysql` container)
-	`-e JOOMLA_DB_USER=...` (defaults to "root")
-	`-e JOOMLA_DB_PASSWORD=...` (defaults to the value of the `MYSQL_ROOT_PASSWORD` environment variable from the linked `mysql` container)
-	`-e JOOMLA_DB_NAME=...` (defaults to "virtuemart")

The following environment variables are only used with the `opentools/docker-virtuemart:j3vm3` tag (where automatic installation of Joomla and VirtueMart is attempted):
-	`-e JOOMLA_ADMIN_USER=...` (defaults to 'admin')
-	`-e JOOMLA_ADMIN_PASSWORD=...` (defaults to 'admin')
-	`-e JOOMLA_ADMIN_EMAIL=...` (defaults to admin@example.com)
-	`-e JOOMLA_SITE_NAME=...` (defaults to 'Joomla Installation')
-	`-e JOOMLA_DB_PREFIX=...` (defaults to Joomla's default of a random prefix)

If the `JOOMLA_DB_NAME` specified does not already exist on the given MySQL server, it will be created automatically upon startup of the `wordpress` container, provided that the `JOOMLA_DB_USER` specified has the necessary permissions to create it.

If you'd like to be able to access the instance from the host without the container's IP, standard port mappings can be used:

```console
$ docker run --name some-virtuemart --link some-mysql:mysql -p 8080:80 -d opentools/virtuemart:tag
```

Then, access it via `http://localhost:8080` or `http://host-ip:8080` in a browser. This will start the VirtueMart Full Installer setup.

If you'd like to use an external database instead of a linked `mysql` container, specify the hostname and port with `JOOMLA_DB_HOST` along with the password in `JOOMLA_DB_PASSWORD` and the username in `JOOMLA_DB_USER` (if it is something other than `root`):

```console
$ docker run --name some-virtuemart -e JOOMLA_DB_HOST=10.1.2.3:3306 \
    -e JOOMLA_DB_USER=... -e JOOMLA_DB_PASSWORD=... -d opentools/virtuemart:tag
```

# Virtuemart 3.x on Joomla 2.5.28 (Full installer)

The stock VirtueMart full installer provides a pre-configured Joomla 2.5.28 installation with sample data installed and the front end already set up with the cart, category and product pages. You can install it from the `opentools/docker-virtuemart:fullinstaller` tag:

```console
$ docker run --name some-virtuemart --link some-mysql:mysql -d \
    -p 8080:80 opentools/virtuemart:fullinstaller
```

This will set up the database and the joomla/virtuemart files, but will leave the installation to you. Simply go to http://localhost:8080/ to run the installer. Unless you changed the defaults with the env variables listed above, the database credentials are:
- database host: mysql
- database: virtuemart
- database user: root
- database password: (the MYSQL_ROOT_PASSWORD given when the mysql container was created)

# Virtuemart 3.x on Joomla 3.x (automated installation)

There is no full installer for VirtueMart 3.x on Joomla 3.x, so this image installed Joomla 3.x and then the Virtuemart 3.x packages, which provide sample data, but do not set up the Joomla front end with the cart, category and product menus and pages. The installation of Joomla and Virtuemart can mostly be done automatically, so in this case, there is no need to go through the installer. However, to configure Joomla, you can give the database prefix, the site name, the admin user/password etc. as env variables when the container is created:

A typical installation of Joomla 3.x with VirtueMart 3.x will thus use a docker line like:
```console
$ docker run --name=some-virtuemart -e JOOMLA_DB_NAME=joomla_j3vm3 -e JOOMLA_DB_PREFIX=vm3 -e JOOMLA_SITE_NAME="My VirtueMart Installation" --link some-mysql:mysql -p 8080:80 -d opentools/virtuemart:j3vm3
```

Available env variables are: `JOOMLA_ADMIN_USER`, `JOOMLA_ADMIN_PASSWORD`, `JOOMLA_ADMIN_EMAIL`, `JOOMLA_SITE_NAME`, `JOOMLA_DB_PREFIX`.

Joomla and Virtuemart itself can be set up automatically, but for technical reasons (Joomla does not have a clean separation of installation and GUI features), the Virtuemart EXT AIO cannot be installed automatically. So after installation, you need to go to Joomla's backend extensions page 
```
http://localhost:8080/administrator/index.php?option=com_installer&view=install```
and install the Virtuemart EXT AIO package from the folder 
```
/usr/src/virtuemart/com_virtumart_ext_aio/
```

# Sources
The docker files to build these images are available on github under the GPL:
https://github.com/open-tools/docker-virtuemart
