FROM jruby:9.0.3-jdk

WORKDIR /usr/src/app/

COPY Gemfile /usr/src/app/
COPY Gemfile.lock /usr/src/app/

COPY vendor/php-parser/composer.json /usr/src/app/vendor/php-parser/
COPY vendor/php-parser/composer.lock /usr/src/app/vendor/php-parser/

RUN curl --silent --location https://deb.nodesource.com/setup_5.x | bash -
RUN apt-get update && apt-get install -y nodejs python openssh-client php5-cli php5-json
RUN gem install bundler --no-ri --no-rdoc && \
    bundle install -j 4 && \
    curl -sS https://getcomposer.org/installer | php

RUN mv composer.phar /usr/local/bin/composer
RUN cd /usr/src/app/vendor/php-parser/ && composer install --prefer-source --no-interaction

RUN adduser app -u 9000

COPY . /usr/src/app
RUN chown -R app .
RUN npm install

USER app

# starting heap, max heap
ENV JAVA_OPTS="-Xms512m -Xmx1280m"

CMD ["/usr/src/app/bin/duplication"]
