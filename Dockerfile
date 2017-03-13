FROM ruby:2.3-alpine

WORKDIR /usr/src/app/

COPY Gemfile /usr/src/app/
COPY Gemfile.lock /usr/src/app/

COPY vendor/php-parser/composer.json /usr/src/app/vendor/php-parser/
COPY vendor/php-parser/composer.lock /usr/src/app/vendor/php-parser/

COPY package.json /usr/src/app/

RUN apk update && apk add python python3 php5-phar php5-openssl php5-cli php5-json php5-zlib php5-xml

ENV NODE_VERSION=v5.12.0 \
    NPM_VERSION=3

# Based on https://github.com/mhart/alpine-node
RUN apk add --no-cache curl make gcc g++ linux-headers binutils-gold gnupg libstdc++ && \
    gpg --keyserver ha.pool.sks-keyservers.net --recv-keys \
      94AE36675C464D64BAFA68DD7434390BDBE9B9C5 \
      FD3A5288F042B6850C66B31F09FE44734EB7990E \
      71DCFD284A79C3B38668286BC97EC7A07EDE3FC1 \
      DD8F2338BAE7501E3DD5AC78C273792F7D83545D \
      C4F0DFFF4E8C1A8236409D08E73BC641CC11F4C8 \
      B9AE9905FFD7803F25714661B63B535A4C206CA9 \
      56730D5401028683275BD23C23EFEFE93C4CFFFE && \
    curl -sSLO https://nodejs.org/dist/${NODE_VERSION}/node-${NODE_VERSION}.tar.xz && \
    curl -sSL https://nodejs.org/dist/${NODE_VERSION}/SHASUMS256.txt.asc | gpg --batch --decrypt | \
      grep " node-${NODE_VERSION}.tar.xz\$" | sha256sum -c | grep . && \
    tar -xf node-${NODE_VERSION}.tar.xz && \
    cd node-${NODE_VERSION} && \
    ./configure --prefix=/usr ${CONFIG_FLAGS} && \
    make -j$(getconf _NPROCESSORS_ONLN) && \
    make install && \
    cd / && \
    if [ -x /usr/bin/npm ]; then \
      npm install -g npm@${NPM_VERSION} && \
      find /usr/lib/node_modules/npm -name test -o -name .bin -type d | xargs rm -rf; \
    fi && \
    apk del curl make gcc g++ linux-headers binutils-gold gnupg ${DEL_PKGS} && \
    rm -rf ${RM_DIRS} /node-${NODE_VERSION}* /usr/share/man /tmp/* /var/cache/apk/* \
      /root/.npm /root/.node-gyp /root/.gnupg /usr/lib/node_modules/npm/man \
      /usr/lib/node_modules/npm/doc /usr/lib/node_modules/npm/html /usr/lib/node_modules/npm/scripts

RUN apk add --update curl && \
    gem install bundler --no-ri --no-rdoc && \
    bundle install -j 4 && \
    curl -sS https://getcomposer.org/installer | php && \
    apk del --purge curl

RUN mv composer.phar /usr/local/bin/composer
RUN cd /usr/src/app/vendor/php-parser/ && composer install --prefer-source --no-interaction
RUN npm install

RUN adduser -u 9000 -D -h /usr/src/app -s /bin/false app
COPY . /usr/src/app
RUN chown -R app:app /usr/src/app

USER app

CMD ["/usr/src/app/bin/duplication"]
