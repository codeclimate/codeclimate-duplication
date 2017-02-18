FROM ruby:2.3-alpine

WORKDIR /usr/src/app/

COPY Gemfile /usr/src/app/
COPY Gemfile.lock /usr/src/app/

COPY vendor/php-parser/composer.json /usr/src/app/vendor/php-parser/
COPY vendor/php-parser/composer.lock /usr/src/app/vendor/php-parser/

COPY package.json /usr/src/app/

# not sure if this is ok to skip. apk's nodejs is 6.7.x:
# RUN curl --silent --location https://deb.nodesource.com/setup_5.x | bash -
RUN apk update && apk add nodejs python python3 php5-phar php5-openssl php5-cli php5-json php5-zlib

# for bundler w/ flay fork... not necessary once off flay fork
RUN apk add git
RUN gem install bundler --no-ri --no-rdoc && \
    bundle install -j 4

RUN apk add curl
RUN curl -sS https://getcomposer.org/installer | php
RUN apk del --purge curl git

RUN mv composer.phar /usr/local/bin/composer
RUN cd /usr/src/app/vendor/php-parser/ && composer install --prefer-source --no-interaction
RUN npm install

RUN adduser -u 9000 -D -h /usr/src/app -s /bin/false app
COPY . /usr/src/app
RUN chown -R app:app /usr/src/app

USER app

CMD ["/usr/src/app/bin/duplication"]
