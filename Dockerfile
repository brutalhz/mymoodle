FROM php:8.1-fpm

ENV DEBIAN_FRONTEND noninteractive \
    MOODLE_URL http://0.0.0.0 \
    MOODLE_ADMIN admin \
    MOODLE_ADMIN_PASSWORD Admin#1234 \
    MOODLE_ADMIN_EMAIL admin@example.com \
    MOODLE_DB_HOST '' \
    MOODLE_DB_PASSWORD '' \
    MOODLE_DB_USER '' \
    MOODLE_DB_NAME '' \
    MOODLE_DB_PORT '3306'


RUN apt-get update && apt-get install -y \
    libfreetype6-dev \
    libjpeg62-turbo-dev \
    libpng-dev \
    libzip-dev \
    libicu-dev \
    libldb-dev libldap2-dev \
    libxml2-dev \
    libxmlrpc-c++8-dev \
    libxslt1-dev \
    zlib1g-dev \
    libmcrypt-dev \
    libmemcached-dev \
    libcurl4-openssl-dev \
    libpq-dev \
    default-mysql-client \
    pwgen \
    aspell \
    git \
    && rm -r /var/lib/apt/lists/*

RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
    && docker-php-ext-install -j$(nproc) gd \
    && docker-php-ext-configure intl \
    && docker-php-ext-install -j$(nproc) intl \
    && docker-php-ext-configure ldap --with-libdir=lib/x86_64-linux-gnu \
    && docker-php-ext-install -j$(nproc) ldap \
    && docker-php-ext-install -j$(nproc) soap xsl zip pdo pdo_mysql curl \
    && docker-php-ext-install mysqli \
    && docker-php-ext-enable mysqli

RUN { \
    echo 'opcache.memory_consumption=128'; \
    echo 'opcache.max_accelerated_files=10000'; \
    echo 'opcache.revalidate_freq=60'; \
    echo 'opcache.use_cwd=1'; \
    echo 'opcache.validate_timestamps=1'; \
    echo 'opcache.save_comments=1'; \
    echo 'opcache.enable_file_override=0'; \
  } > /usr/local/etc/php/conf.d/opcache-recommended.ini

RUN apt-get update && apt-get install -y default-mysql-client

RUN git clone -b MOODLE_403_STABLE --depth 1 https://github.com/moodle/moodle.git /var/www/html
RUN chown -R www-data:www-data /var/www/html
COPY ./config.php /var/www/html/config.php
COPY ./entrypoint.sh /usr/local/bin/entrypoint.sh
RUN chmod +x /usr/local/bin/entrypoint.sh

RUN apt-get clean autoclean && apt-get autoremove -y && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /var/lib/dpkg/* /var/lib/cache/* /var/lib/log/*

RUN chown root:root /usr/local/bin/entrypoint.sh && \
    chmod +x /usr/local/bin/entrypoint.sh

EXPOSE 9000

ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["php-fpm"]
