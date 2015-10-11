FROM joomla:latest
MAINTAINER Reinhold Kainhofer <reinhold@kainhofer.com>

# Enable Apache Rewrite Module
RUN a2enmod rewrite

# Install PHP extensions
RUN apt-get update && apt-get install -y libpng12-dev libjpeg-dev zip unzip && rm -rf /var/lib/apt/lists/* \
	&& docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
	&& docker-php-ext-install gd
RUN docker-php-ext-install mysqli

VOLUME /var/www/html

# Define Joomla version and expected SHA1 signature
ENV VM_VERSION 3.0.10
ENV VM_MD5 a684928d8b1e2dde0c9ac8e047d65038

# Download package and extract to web volume
RUN curl -o virtuemart.zip -SL http://dev.virtuemart.net/attachments/download/972/com_virtuemart.${VM_VERSION}_extract_first.zip \
	&& echo "$VM_MD5 *virtuemart.zip" | md5sum -c - \
	&& mkdir /usr/src/virtuemart \
	&& unzip virtuemart.zip -d /usr/src/virtuemart \
	&& rm virtuemart.zip \
	&& chown -R www-data:www-data /usr/src/virtuemart

# Copy init scripts and custom .htaccess
COPY docker-entrypoint.sh /entrypoint.sh
COPY makedb.php /makedb.php
COPY install-joomla.php /usr/src/joomla/installation/install.php
COPY install-joomla-extension.php /usr/src/joomla/cli/install-joomla-extension.php

ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]
