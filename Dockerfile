FROM codeclimate/codeclimate-parser:b264
LABEL maintainer="Code Climate <hello@codeclimate.com>"

# Reset from base image
USER root

WORKDIR /usr/src/app/

# 3x normal default
ENV RUBY_THREAD_MACHINE_STACK_SIZE=3145728

RUN apt-get update && \
  RUNLEVEL=1 apt-get install --yes --no-install-recommends \
    python2.7

COPY Gemfile* package.json package-lock.json ./
COPY vendor/php-parser/composer* ./vendor/php-parser/

RUN bundle install --jobs 4 --quiet && \
    composer install --no-interaction --quiet --working-dir ./vendor/php-parser && \
    npm install

COPY . ./
RUN chown -R app:app ./

USER app

CMD ["/usr/src/app/bin/duplication"]
