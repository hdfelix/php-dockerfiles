# PHP image setup
FROM php:8.0.15-apache

LABEL maintainer='Hector D. Felix <hdfelix@gmail.com>'
LABEL date='2023-02-06'

ENV ACCEPT_EULA=Y \
    TERM='xterm' \
    LANG='C.UTF-8'

# Fix debconf warnings upon build
ARG DEBIAN_FRONTEND=noninteractive

RUN curl -sL https://deb.nodesource.com/setup_14.x | bash -
RUN apt-get install -y nodejs

# Install selected extensions and other stuff
RUN apt-get update \
    && apt-get install -y --no-install-recommends curl \
      apt-transport-https \
      apt-utils \
      git \
      build-essential \
      libmcrypt-dev \
      libicu-dev \
      zlib1g-dev \
      libpq-dev \
      libfreetype6-dev \
      libjpeg62-turbo-dev \
      gettext \
      gnupg \
      libonig-dev \
      libxml2-dev \
      rsync \
      ripgrep \
      vim \
      unzip \
      wget \
      zip \
      iputils-ping \
      libz-dev \
\
      # for network troubleshooting
      net-tools \
      network-manager-config-connectivity-debian \
\
    # fast search
    silversearcher-ag \
\
    # standard cleanup
    && apt-get autoremove -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/*

# install bat
RUN curl -L https://github.com/sharkdp/bat/releases/download/v0.18.2/bat-v0.18.2-x86_64-unknown-linux-gnu.tar.gz | tar -C /usr/local/src -zxf - &&\
    ln -s /usr/local/src/bat-v0.18.2-x86_64-unknown-linux-gnu/bat /usr/local/bin/bat

# Install MS ODBC & PDO Drivers for SQL Server (Debian 10)
RUN curl https://packages.microsoft.com/keys/microsoft.asc | apt-key add - \
    && curl https://packages.microsoft.com/config/debian/11/prod.list > /etc/apt/sources.list.d/mssql-release.list \
    && apt-get update \
    && apt-get install -y --no-install-recommends \
         msodbcsql17 \
         unixodbc-dev \
\
         # for testing w/o pdo
         mssql-tools \
\
    # make sqlcmd accessible from bash shell for login sessions
    && echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bash_profile \
\
    # makesqlcmd/bpc accessible from the bash shell for interactive/non-login sessions:
    && echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc \
\
    # PECL
    && pecl install sqlsrv \
    && pecl install pdo_sqlsrv \
    && echo "extension=pdo_sqlsrv.so" >> `php --ini | grep "Scan for additional .ini files" | sed -e "s|.*:\s*||"`/30-pdo_sqlsrv.ini \
    && echo "extension=sqlsrv.so" >> `php --ini | grep "Scan for additional .ini files" | sed -e "s|.*:\s*||"`/30-sqlsrv.ini \
    && echo "extension=gettext.so" >> `php --ini | grep "Scan for additional .ini files" | sed -e "s|.*:\s*||"`/40-gettext.ini \
    && apt-get clean; rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /usr/share/doc/* \
\
# Install needed dependencies
&& echo 'export PATH="$PATH:/opt/mssql-tools/bin"' >> ~/.bashrc \
\
# Install required extensions
&& docker-php-ext-install \
      iconv \
      intl \
      mysqli \
      pdo_mysql \
\
  # Install xdebug
  && pecl install xdebug \
  && docker-php-ext-enable xdebug \
  && echo "error_reporting = E_ALL" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
  && echo "display_startup_errors = On" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
  && echo "display_errors = On" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
  && echo "xdebug.mode=debug,develop" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
  && echo "xdebug.start_with_request=yes" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
  && echo "xdebug.discover_client_host=1" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
  && echo "xdebug.idekey=\"PHPSTORM\"" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
  && echo "xdebug.client_port=9003" >> /usr/local/etc/php/conf.d/docker-php-ext-xdebug.ini \
\
  # Composer installation.
  && curl -sS https://getcomposer.org/installer | php \
  && mv composer.phar /usr/bin/composer \
  && composer selfupdate
