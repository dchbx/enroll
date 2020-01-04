ARG RUBY_VERSION
FROM ruby:$RUBY_VERSION

ARG BUNDLER_VERSION
ARG NODE_MAJOR
ARG YARN_VERSION

# Add NodeJS to sources list
RUN curl -sL https://deb.nodesource.com/setup_$NODE_MAJOR.x | bash -

# Add Yarn to the sources list
RUN curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add - \
  && echo 'deb http://dl.yarnpkg.com/debian/ stable main' > /etc/apt/sources.list.d/yarn.list

# Install dependencies
COPY .docker/development/app/Aptfile /tmp/Aptfile
RUN apt-get update -qq && DEBIAN_FRONTEND=noninteractive apt-get -yq dist-upgrade && \
  DEBIAN_FRONTEND=noninteractive apt-get install -yq --no-install-recommends \
    build-essential \
    nodejs \
    yarn=$YARN_VERSION-1 \
    $(cat /tmp/Aptfile | xargs) && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* && \
    truncate -s 0 /var/log/*log

# Configure bundler and PATH
ENV LANG=C.UTF-8 \
  GEM_HOME=/bundle \
  BUNDLE_JOBS=4 \
  BUNDLE_RETRY=3
ENV BUNDLE_PATH $GEM_HOME
ENV BUNDLE_APP_CONFIG=$BUNDLE_PATH \
  BUNDLE_BIN=$BUNDLE_PATH/bin
ENV PATH /app/bin:$BUNDLE_BIN:$PATH

# Upgrade RubyGems and install required Bundler version
RUN gem update --system && \
    gem install bundler:$BUNDLER_VERSION

# Setup webpacker JS
RUN yarn install

# Create a directory for the app code
RUN mkdir -p /app

WORKDIR /app

# Setting env up
ENV RAILS_ENV='development'
ENV NODE_ENV='development'

# Adding gems
COPY Gemfile Gemfile
COPY Gemfile.lock Gemfile.lock
# Ordered in of less likely to be changed
COPY project_gems/effective_datatables-2.6.14 project_gems/effective_datatables-2.6.14
COPY project_gems/mongoid_userstamp-0.4.0 project_gems/mongoid_userstamp-0.4.0
COPY components/transport_gateway components/transport_gateway
COPY components/transport_profiles components/transport_profiles
COPY components/notifier components/notifier
COPY components/sponsored_benefits components/sponsored_benefits
COPY components/benefit_markets components/benefit_markets
COPY components/benefit_sponsors components/benefit_sponsors

RUN bundle install && yarn install --check-files
