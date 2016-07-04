FROM alpine:latest

RUN apk add --no-cache \
  build-base \
  git \
  ruby-dev \
  ruby-bundler \
  nodejs-lts \
  curl \
  php5 \
  php5-openssl \
  php5-json \ 
  php5-phar \
  python3 \
  && curl -sS https://getcomposer.org/installer | php -- --install-dir=/usr/bin --filename=composer

WORKDIR /usr/src/app/

COPY Gemfile /usr/src/app/
COPY Gemfile.lock /usr/src/app/
COPY vendor/php-parser/composer.json /usr/src/app/vendor/php-parser/
COPY vendor/php-parser/composer.lock /usr/src/app/vendor/php-parser/

RUN bundle install -j 4
RUN cd /usr/src/app/vendor/php-parser/ && composer install --prefer-source --no-interaction

CMD ["/bin/sh"]

RUN adduser app -u 9000 -D

COPY . /usr/src/app
RUN chown -R app .
RUN npm install

USER app

ENV JAVA_OPTS="-XX:+UseParNewGC -XX:MinHeapFreeRatio=5 -XX:MaxHeapFreeRatio=10"

CMD ["/usr/src/app/bin/duplication"]
