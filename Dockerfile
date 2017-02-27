FROM ruby:2.3-alpine

WORKDIR /usr/src/app/

COPY Gemfile /usr/src/app/
COPY Gemfile.lock /usr/src/app/

COPY vendor/php-parser/composer.json /usr/src/app/vendor/php-parser/
COPY vendor/php-parser/composer.lock /usr/src/app/vendor/php-parser/

COPY package.json /usr/src/app/

RUN apk update && apk add nodejs python python3 php5-phar php5-openssl php5-cli php5-json php5-zlib php5-xml

RUN apk add curl && \
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
