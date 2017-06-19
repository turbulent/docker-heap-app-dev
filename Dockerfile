FROM turbulent/heap-app:4.0.0
MAINTAINER Benoit Beausejour <b@turbulent.ca>
ENV heap-app-dev 4.0.0

ENV DEBIAN_FRONTEND noninteractive

COPY composer-installer.php /tmp/
COPY nodesource.gpg.key /tmp/
 
# Adding nodesource repository before update
RUN apt-key add /tmp/nodesource.gpg.key && \
 echo 'deb https://deb.nodesource.com/node_6.x trusty main' > /etc/apt/sources.list.d/nodesource.list && \
 echo 'deb-src https://deb.nodesource.com/node_6.x trusty main' >> /etc/apt/sources.list.d/nodesource.list 

RUN apt-get update && \
  apt-get -y install \
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
    python-sphinx \
    mysql-client \
    nodejs \
    icu-devtools \
    php7.1-xdebug \
    graphviz && \
  rm -rf /var/lib/apt/lists/*

RUN php /tmp/composer-installer.php --version=1.3.2 --install-dir=/usr/local/bin --filename=composer

RUN npm install -g node-gyp && \
  npm cache clean


# Install Symfony utility
RUN mkdir -p /usr/local/bin && \
  curl -LsS https://symfony.com/installer -o /usr/local/bin/symfony && \
  chmod a+x /usr/local/bin/symfony

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
