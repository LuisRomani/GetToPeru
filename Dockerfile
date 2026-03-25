FROM php:8.2-apache AS base

# Set working directory
WORKDIR /var/www/html

# Install system dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    libpq-dev \
    libonig-dev \
    libxml2-dev \
    libicu-dev \
    curl \
    git \
    msmtp \
    && rm -rf /var/lib/apt/lists/*

# Install PHP extensions
RUN docker-php-ext-install \
    pdo \
    pdo_mysql \
    pdo_pgsql \
    mbstring \
    xml \
    soap \
    && docker-php-ext-enable pdo pdo_mysql pdo_pgsql mbstring xml soap

# Enable Apache modules
RUN a2enmod rewrite headers ssl

# Configure Apache DocumentRoot
RUN sed -i 's|DocumentRoot /var/www/html|DocumentRoot /var/www/html|g' /etc/apache2/sites-enabled/000-default.conf

# Copy application files
COPY --chown=www-data:www-data . .

# Set PHP ini settings for production and configure sendmail wrapper
RUN { \
    echo 'memory_limit = 256M'; \
    echo 'max_execution_time = 60'; \
    echo 'upload_max_filesize = 100M'; \
    echo 'post_max_size = 100M'; \
    echo 'error_log = /var/log/php-error.log'; \
    echo 'display_errors = Off'; \
    echo 'log_errors = On'; \
    echo 'sendmail_path = "/usr/sbin/sendmail -t -i"'; \
    } > /usr/local/etc/php/conf.d/production.ini

# Create necessary directories and msmtp config for local Postfix
RUN mkdir -p /var/log/apache2 && \
    chown -R www-data:www-data /var/www/html /var/log/apache2 && \
    { \
    echo 'defaults'; \
    echo 'auth off'; \
    echo 'tls off'; \
    echo 'domain gettoperu.local'; \
    echo 'host postfix'; \
    echo 'port 25'; \
    echo 'from noreply@gettoperu.local'; \
    echo ''; \
    echo 'account default'; \
    echo 'host postfix'; \
    echo 'port 25'; \
    echo 'from noreply@gettoperu.local'; \
    } > /etc/msmtprc && \
    chmod 644 /etc/msmtprc && \
    { \
    echo '#!/bin/bash'; \
    echo 'exec /usr/bin/msmtp "$@"'; \
    } > /usr/sbin/sendmail && \
    chmod 755 /usr/sbin/sendmail

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost/index.html || exit 1

# Expose port
EXPOSE 80

# Start Apache in foreground
CMD ["apache2-foreground"]
