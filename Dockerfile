FROM codeclimate/codeclimate-parser:b850
LABEL maintainer="Code Climate <hello@codeclimate.com>"

# Reset from base image
USER root

WORKDIR /usr/src/app/

# 3x normal default
ENV RUBY_THREAD_MACHINE_STACK_SIZE=3145728

RUN apt-get update && \
  RUNLEVEL=1 apt-get install --yes --no-install-recommends \
    python2.7

COPY Gemfile* ./

RUN bundle install --jobs 4 --quiet
COPY . ./
RUN chown -R app:app ./

USER app

ENTRYPOINT ["/usr/src/app/entrypoint"]
CMD ["/usr/src/app/bin/duplication", "/code", "/config.json"]
