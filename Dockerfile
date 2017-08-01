FROM codeclimate/codeclimate-parser:b201
MAINTAINER Code Climate <hello@codeclimate.com>

# Reset from base image
USER root

RUN mkdir /home/app/codeclimate-duplication
WORKDIR /home/app/codeclimate-duplication

COPY Gemfile ./Gemfile
COPY Gemfile.lock ./Gemfile.lock
RUN bundle install

COPY . .
RUN chown -R app:app /home/app
USER app

ENTRYPOINT ["./entrypoint"]
CMD ["./bin/duplication"]
