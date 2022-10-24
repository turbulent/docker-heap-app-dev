FROM turbulent/heap-app:6.2.0
LABEL MAINTAINER="Benoit Beausejour <b@turbulent.ca>"
ENV heap-app-dev 7.2.0

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
    php8.1-ast \
    php8.1-xdebug \
    php8.1-dev \
    php-pear \
    graphviz \
    rsync \
    protobuf-compiler \
    libpng-dev && \
  pecl install protobuf && \
  apt-get remove -y php-pear php8.1-dev && \
  apt-get autoremove -y && \
  rm -rf /var/lib/apt/lists/*

# Install Composer
COPY --from=composer:2.4.3 /usr/bin/composer /usr/local/bin/composer
RUN mkdir -p /home/heap/.composer
RUN chown -R heap:www-data /home/heap

# Install Buf
COPY --from=bufbuild/buf:1.9.0 /usr/local/bin/buf /usr/local/bin/buf

# Install grpc_php_plugin, move it to protoc-gen-grpc-php as Buf looks for protoc-gen-PLUGIN_NAME in PATH
RUN apt-get update && \
    apt-get install -y && \
    apt-get -y install cmake && \
    cd /tmp && \
    git clone --depth 1 -b v1.50.0 https://github.com/grpc/grpc && \
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

# Install xdebug config
COPY xdebug.ini /etc/php/8.1/mods-available/xdebug.ini

# Volumes for package manager configs
VOLUME ["/usr/etc/npmrc"]
VOLUME ["/home/heap/.composer"]

EXPOSE 8080
EXPOSE 9004
