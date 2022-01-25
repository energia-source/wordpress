FROM amd64/alpine:3.15

ENV STARTUP_COMMAND_RUN_PHP="php-fpm7 -F" \
    STARTUP_COMMAND_RUN_NGINX="nginx"

ARG PHP_FPM_USER="www" \
    PHP_FPM_GROUP="www" \
    PHP_FPM_LISTEN_MODE="0660" \
    PHP_MEMORY_LIMIT="8192M" \
    PHP_MAX_UPLOAD="7168M" \
    PHP_MAX_FILE_UPLOAD="4" \
    PHP_MAX_EXECUTION_TIME="300" \
    PHP_MAX_INPUT_VARS="3000" \
    PHP_MAX_POST="7680M" \
    PHP_DISPLAY_ERRORS="On" \
    PHP_DISPLAY_STARTUP_ERRORS="On" \
    PHP_ERROR_REPORTING="E_COMPILE_ERROR\|E_RECOVERABLE_ERROR\|E_ERROR\|E_CORE_ERROR" \
    PHP_CGI_FIX_PATHINFO="0" \
    TIMEZONE="UTC"

RUN apk update && \
    apk add --no-cache bash curl less vim nginx ca-certificates git zip \
    libmcrypt-dev zlib-dev gmp-dev \
    freetype-dev libjpeg-turbo-dev libpng-dev \
    php7-fpm php7-json php7-zlib php7-xml php7-pdo php7-phar php7-openssl \
    php7-pdo_mysql php7-mysqli php7-session \
    php7-gd php7-iconv php7-mcrypt php7-gmp php7-zip \
    php7-curl php7-opcache php7-ctype php7-apcu \
    php7-intl php7-bcmath php7-dom php7-mbstring php7-xmlreader php7-simplexml mysql-client curl && \
    apk add --no-cache musl && \
    apk add --no-cache tzdata && \
    rm -rf /var/cache/apk/* && \
    mkdir -p /app

COPY wrapper.sh /
COPY nginx.conf /etc/nginx/nginx.conf

VOLUME /app

RUN mkdir -p /tmp/nginx && \
    adduser -D -g www www && \
    chown -R www:www /var/lib/nginx /var/log/nginx /tmp/nginx /app /var/log/php7 && \
    rm -Rf /etc/nginx/sites-available && \
    rm -Rf /etc/nginx/sites-enabled && \
    chmod +x wrapper.sh && \
    cp -r /usr/share/zoneinfo/${TIMEZONE} /etc/localtime && \
    echo "${TIMEZONE}" > /etc/timezone

RUN sed -i "s|;*listen.owner\s*=\s*.*|listen.owner = ${PHP_FPM_USER}|g" /etc/php7/php-fpm.d/www.conf && \
    sed -i "s|;*listen.group\s*=\s*.*|listen.group = ${PHP_FPM_GROUP}|g" /etc/php7/php-fpm.d/www.conf && \
    sed -i "s|;*listen.mode\s*=\s*.*|listen.mode = ${PHP_FPM_LISTEN_MODE}|g" /etc/php7/php-fpm.d/www.conf && \
    sed -i "s|;*user\s*=\s*.*|user = ${PHP_FPM_USER}|g" /etc/php7/php-fpm.d/www.conf && \
    sed -i "s|;*group\s*=\s*.*|group = ${PHP_FPM_GROUP}|g" /etc/php7/php-fpm.d/www.conf && \
    sed -i "s|;*log_level\s*=\s*.*|log_level = notice|g" /etc/php7/php-fpm.d/www.conf && \
    sed -i "s|;*display_errors\s*=\s*.*|display_errors = ${PHP_DISPLAY_ERRORS}|i" /etc/php7/php.ini && \
    sed -i "s|;*display_startup_errors\s*=\s*.*|display_startup_errors = ${PHP_DISPLAY_STARTUP_ERRORS}|i" /etc/php7/php.ini && \
    sed -i "s|;*error_reporting\s*=\s*.*|error_reporting = ${PHP_ERROR_REPORTING}|i" /etc/php7/php.ini && \
    sed -i "s|;*memory_limit\s*=\s*.*|memory_limit = ${PHP_MEMORY_LIMIT}|i" /etc/php7/php.ini && \
    sed -i "s|;*upload_max_filesize\s*=\s*.*|upload_max_filesize = ${PHP_MAX_UPLOAD}|i" /etc/php7/php.ini && \
    sed -i "s|;*max_file_uploads\s*=\s*.*|max_file_uploads = ${PHP_MAX_FILE_UPLOAD}|i" /etc/php7/php.ini && \
    sed -i "s|;*post_max_size\s*=\s*.*|post_max_size = ${PHP_MAX_POST}|i" /etc/php7/php.ini && \
    sed -i "s|;*max_input_vars\s*=\s*.*|max_input_vars = ${PHP_MAX_INPUT_VARS}|i" /etc/php7/php.ini && \
    sed -i "s|;*max_execution_time\s*=\s*.*|max_execution_time = ${PHP_MAX_EXECUTION_TIME}|i" /etc/php7/php.ini && \
    sed -i "s|;*cgi.fix_pathinfo\s*=\s*.*|cgi.fix_pathinfo= ${PHP_CGI_FIX_PATHINFO}|i" /etc/php7/php.ini && \
    sed -i "s|;*date.timezone\s*=\s*.*|date.timezone = ${TIMEZONE}|i" /etc/php7/php.ini

EXPOSE 8080

USER www

ENTRYPOINT /wrapper.sh