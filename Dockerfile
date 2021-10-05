FROM turbulent/heap-app:6.0.2
LABEL MAINTAINER="Benoit Beausejour <b@turbulent.ca>"
ENV heap-app-dev 7.0.2

ENV DEBIAN_FRONTEND noninteractive

COPY composer-installer.php /tmp/
COPY nodesource.gpg.key /tmp/

RUN apt-get update && \
  apt-get install -y \
    ca-certificates \
    gnupg && \
  apt-key add /tmp/nodesource.gpg.key && \
  echo 'deb https://deb.nodesource.com/node_14.x focal main' > /etc/apt/sources.list.d/nodesource.list && \
  echo 'deb-src https://deb.nodesource.com/node_14.x focal main' >> /etc/apt/sources.list.d/nodesource.list && \
  apt-get update && \
  apt-get -y install \
    openssl \
    ca-certificates \
    libedit-dev \
    rlwrap \
    curl \
    telnet \
    finger \
    wget \
    vim \
    entr \
    build-essential \
    m4 \
    git-core \
    python3-sphinx \
    mysql-client \
    nodejs \
    icu-devtools \
    php7.2-ast \
    php7.2-xdebug \
    graphviz \
    rsync && \
  apt-get autoremove && \
  rm -rf /var/lib/apt/lists/*

RUN php /tmp/composer-installer.php --version=1.9.1 --install-dir=/usr/local/bin --filename=composer
RUN mkdir -p /home/heap/.composer
RUN chown -R heap:www-data /home/heap

RUN npm install -g node-gyp && \
  npm cache verify

# Install PHPUnit
RUN curl -LsS https://phar.phpunit.de/phpunit-7.phar -o /usr/local/bin/phpunit && \
  chmod a+x /usr/local/bin/phpunit

# Install Codeception
RUN curl -LsS http://codeception.com/releases/2.4.0/codecept.phar -o /usr/local/bin/codecept && \
  chmod a+x /usr/local/bin/codecept

# Install Codesniffer
RUN curl -LsS https://squizlabs.github.io/PHP_CodeSniffer/phpcs.phar -o /usr/local/bin/phpcs && \
  curl -LsS https://squizlabs.github.io/PHP_CodeSniffer/phpcbf.phar -o /usr/local/bin/phpcbf && \
  chmod a+x /usr/local/bin/phpcs && \
  chmod a+x /usr/local/bin/phpcbf

# Install phpDocumentor
RUN curl -LsS http://phpdoc.org/phpDocumentor.phar -o /usr/local/bin/phpdoc && \
  chmod a+x /usr/local/bin/phpdoc

# Install xdebug config
COPY xdebug.ini /etc/php/7.2/mods-available/xdebug.ini

# Webgrind
ADD webgrind-v1.5.0.zip /var/www/
RUN cd /var/www && \
  unzip webgrind-v1.5.0 && \
  mv webgrind-1.5.0 webgrind && \
  rm webgrind-v1.5.0.zip
COPY nginx.conf.webgrind.tmpl /systpl/nginx.conf.webgrind.tmpl
RUN sed -i '$ d' /systpl/nginx.conf.tmpl && \
  cat /systpl/nginx.conf.webgrind.tmpl >> /systpl/nginx.conf.tmpl

# Volumes for package manager configs
VOLUME ["/usr/etc/npmrc"]
VOLUME ["/home/heap/.composer"]

EXPOSE 8080
EXPOSE 9004
