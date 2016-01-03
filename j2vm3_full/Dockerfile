FROM php:5.6-apache
MAINTAINER Reinhold Kainhofer <reinhold@kainhofer.com>

# Enable Apache Rewrite Module
RUN a2enmod rewrite


# Install PHP extensions
RUN apt-get update && apt-get install -y libpng12-dev libjpeg-dev zip unzip && rm -rf /var/lib/apt/lists/* \
	&& docker-php-ext-configure gd --with-png-dir=/usr --with-jpeg-dir=/usr \
	&& docker-php-ext-install gd
RUN docker-php-ext-install mysqli

VOLUME /var/www/html

# Install MySQL (will only be started if needed)
# RUN apt-get update && apt-get install -y mysql-server && rm -rf /var/lib/apt/lists/*


# Define Joomla version and expected SHA1 signature
ENV VMFULL_VERSION 3.0.12
ENV VMFULL_MD5 68dfeda59610bd798c0f03a7fb9340df
ENV VMFULL_POSTFIX "_with_security_patch"

# Download package and extract to web volume
RUN curl -o virtuemart.zip -SL http://dev.virtuemart.net/attachments/download/983/VirtueMart${VMFULL_VERSION}_Joomla_2.5.29-Stable-Full_Package${VMFULL_POSTFIX}.zip \
	&& echo "$VMFULL_MD5 *virtuemart.zip" | md5sum -c - \
	&& mkdir /usr/src/virtuemart \
	&& unzip virtuemart.zip -d /usr/src/virtuemart \
	&& rm virtuemart.zip \
	&& chown -R www-data:www-data /usr/src/virtuemart

# Copy init scripts and custom .htaccess
COPY docker-entrypoint.sh /entrypoint.sh
COPY makedb.php /makedb.php

ENTRYPOINT ["/entrypoint.sh"]
CMD ["apache2-foreground"]
