FROM turbulent/heap-app:6.1.0
LABEL MAINTAINER="Benoit Beausejour <b@turbulent.ca>"
ENV heap-app-dev 7.1.0

ENV DEBIAN_FRONTEND noninteractive

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
    php7.4-ast \
    php7.4-xdebug \
    php7.4-dev \
    php-pear \
    graphviz \
    rsync \
    protobuf-compiler \
    libpng-dev && \
  pecl install protobuf && \
  apt-get remove -y php-pear php7.4-dev && \
  apt-get autoremove -y && \
  rm -rf /var/lib/apt/lists/*

# Install Composer
COPY --from=composer:2.3.10 /usr/bin/composer /usr/local/bin/composer
RUN mkdir -p /home/heap/.composer
RUN chown -R heap:www-data /home/heap

# Install Buf
COPY --from=bufbuild/buf:1.4.0 /usr/local/bin/buf /usr/local/bin/buf

# Install grpc_php_plugin, move it to protoc-gen-grpc-php as Buf looks for protoc-gen-PLUGIN_NAME in PATH
RUN apt-get update && \
    apt-get install -y && \
    apt-get -y install cmake && \
    cd /tmp && \
    git clone --depth 1 -b v1.45.2 https://github.com/grpc/grpc && \
    cd grpc && \
    git submodule update --init && \
    mkdir -p cmake/build && \
    cd cmake/build && \
    cmake ../.. && \
    make protoc grpc_php_plugin && \
    mv grpc_php_plugin /usr/bin/protoc-gen-grpc-php && \
    rm -rf /tmp/* && \
    apt-get remove -y cmake && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/*

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
COPY xdebug.ini /etc/php/7.4/mods-available/xdebug.ini

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
