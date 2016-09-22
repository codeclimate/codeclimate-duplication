FROM jruby:9.0.3-jdk

WORKDIR /usr/src/app/

COPY Gemfile /usr/src/app/
COPY Gemfile.lock /usr/src/app/

COPY vendor/php-parser/composer.json /usr/src/app/vendor/php-parser/
COPY vendor/php-parser/composer.lock /usr/src/app/vendor/php-parser/

COPY package.json /usr/src/app/

RUN curl --silent --location https://deb.nodesource.com/setup_5.x | bash - && \
    apt-get update && apt-get install -y nodejs python openssh-client php5-cli php5-json
RUN gem install bundler --no-ri --no-rdoc && \
    bundle install -j 4 && \
    curl -sS https://getcomposer.org/installer | php

RUN mv composer.phar /usr/local/bin/composer
RUN cd /usr/src/app/vendor/php-parser/ && composer install --prefer-source --no-interaction
RUN npm install

RUN adduser app -u 9000

COPY . /usr/src/app
RUN chown -R app .

USER app

ENV JAVA_OPTS="-XX:+UseParallelGC -XX:MinHeapFreeRatio=40 -XX:MaxHeapFreeRatio=70 -Xmx1024m"
CMD ["/usr/src/app/bin/duplication"]
