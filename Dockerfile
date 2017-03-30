FROM codeclimate/codeclimate-duplication-base

WORKDIR /usr/src/app/

COPY vendor/php-parser/composer.json /usr/src/app/vendor/php-parser/
COPY vendor/php-parser/composer.lock /usr/src/app/vendor/php-parser/
RUN mv composer.phar /usr/local/bin/composer
RUN cd /usr/src/app/vendor/php-parser/ && composer install --prefer-source --no-interaction

COPY package.json /usr/src/app/
RUN npm install

COPY Gemfile .
COPY Gemfile.lock .
RUN bundle install -j4

COPY . /usr/src/app
RUN chown -R app:app /usr/src/app

USER app

CMD ["/usr/src/app/bin/duplication"]
