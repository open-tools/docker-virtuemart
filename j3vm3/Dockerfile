FROM joomla:latest
MAINTAINER Reinhold Kainhofer <reinhold@kainhofer.com>

# Enable Apache Rewrite Module
RUN a2enmod rewrite

RUN apt-get update

# Install PHP extensions
RUN apt-get install -y libpng12-dev libjpeg-dev zip unzip sudo \
	&& docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
	&& docker-php-ext-install gd
RUN docker-php-ext-install mysqli

VOLUME /var/www/html

# Install MySQL (will only be started if needed)
# RUN export DEBIAN_FRONTEND=noninteractive
RUN echo "mysql-server-5.5 mysql-server/root_password password root" | debconf-set-selections
RUN echo "mysql-server-5.5 mysql-server/root_password_again password root" | debconf-set-selections
RUN DEBIAN_FRONTEND=noninteractive apt-get install -y mysql-server

RUN apt-get install -y supervisor


# Define Joomla version and expected SHA1 signature
ENV VM_VERSION 3.0.12
ENV VM_DLDIR 979
ENV VM_MD5 2b9855cd0de8e7073fb3c4c7d633c5a3

# Download package and extract to web volume
RUN curl -o virtuemart.zip -SL http://dev.virtuemart.net/attachments/download/${VM_DLDIR}/com_virtuemart.${VM_VERSION}_extract_first.zip \
	&& echo "$VM_MD5 *virtuemart.zip" | md5sum -c - \
	&& mkdir /usr/src/virtuemart \
	&& unzip virtuemart.zip -d /usr/src/virtuemart \
	&& rm virtuemart.zip \
	&& chown -R www-data:www-data /usr/src/virtuemart \
	&& unzip /usr/src/virtuemart/com_virtuemart*_ext_aio.zip -d /usr/src/virtuemart/com_virtumart_ext_aio/ \
	&& rm /usr/src/virtuemart/com_virtuemart*_ext_aio.zip

# Clean up the apt cache etc.
RUN rm -rf /var/lib/apt/lists/* 

# Copy init scripts and custom .htaccess
RUN echo "[program:mysql]\ncommand=/usr/bin/pidproxy /run/mysqld/mysqld.pid /usr/bin/mysqld_safe \nautorestart=true\n" > /etc/supervisor/conf.d/mysql.conf.save
COPY supervisord.conf /etc/supervisor/supervisord.conf
COPY docker-entrypoint.sh /entrypoint.sh
COPY makedb.php /makedb.php
COPY install-joomla.php /usr/src/joomla/installation/install.php
COPY install-joomla-extension.php /usr/src/joomla/cli/install-joomla-extension.php

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf"]
