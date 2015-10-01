FROM alpine:edge

WORKDIR /usr/src/app/

COPY Gemfile /usr/src/app/
COPY Gemfile.lock /usr/src/app/

COPY vendor/php-parser/composer.json /usr/src/app/vendor/php-parser/
COPY vendor/php-parser/composer.lock /usr/src/app/vendor/php-parser/

RUN apk --update add python nodejs php-cli php-json php-phar php-openssl php-xml curl\
    ruby ruby-io-console ruby-dev ruby-bundler build-base && \
    bundle install -j 4 && \
    apk del build-base && rm -fr /usr/share/ri && \
    curl -sS https://getcomposer.org/installer | php

RUN mv composer.phar /usr/local/bin/composer
RUN cd /usr/src/app/vendor/php-parser/ && composer install

RUN adduser -u 9000 -D app

COPY . /usr/src/app
RUN npm install

USER app

CMD ["/usr/src/app/bin/duplication"]
