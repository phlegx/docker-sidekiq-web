# Sidekiq Web
#
# Description: Dockerfile for standalone Sidekiq Web with Puma.
# Author: Egon Zemmer, Phlegx Systems Technologies GmbH

# Set base image.
ARG RUBY_VERSION=latest
FROM ruby:$RUBY_VERSION AS builder

RUN apt-get update && \
    apt-get install -y build-essential

# Add and enter working directory.
RUN mkdir -p /usr/src/sidekiq
WORKDIR /usr/src/sidekiq

# Add gems.
ARG SIDEKIQ_VERSION=~>7.0
ARG SIDEKIQ_CRON_VERSION=~>2.0
ARG PUMA_VERSION=~>6.0
RUN echo "source 'https://rubygems.org'; \
          gem 'rackup'; \
          gem 'rack-session'; \
          gem 'hiredis-client'; \
          gem 'sidekiq', '$SIDEKIQ_VERSION'; \
          gem 'sidekiq-cron', '$SIDEKIQ_CRON_VERSION'; \
          gem 'puma', '$PUMA_VERSION'" > Gemfile

# Install gems.
RUN bundle config set without 'development test' && \
    bundle install --jobs=3 --retry=3

FROM ruby:$RUBY_VERSION

# Copy Gemfiles and bundled gems to clean image.
COPY --from=builder /usr/src/sidekiq/ /usr/src/sidekiq/
COPY --from=builder /usr/local/bundle/ /usr/local/bundle/

# Enter working directory.
WORKDIR /usr/src/sidekiq

# Create a dedicated user for running sidekiq web.
RUN adduser --disabled-password --uid 1000 --gecos '' sidekiq-web
RUN chown -R sidekiq-web:sidekiq-web /usr/src/sidekiq

# Set the user for RUN, CMD or ENTRYPOINT calls from now on.
USER sidekiq-web

# Add redis client file.
COPY --chown=sidekiq-web redis_config.rb /usr/src/sidekiq/

# Add rackup file.
COPY --chown=sidekiq-web config.ru /usr/src/sidekiq/

# Expose port for sidekiq web.
EXPOSE 9292

# Execute rackup.
CMD ["bundle", "exec", "rackup", "-o", "0.0.0.0", "config.ru"]
