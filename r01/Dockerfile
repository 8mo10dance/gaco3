FROM ghcr.io/8mo10dance/ruby:3.2.0

COPY apt-packages .

RUN apt-get update -qq && \
    xargs -a apt-packages apt-get install --no-install-recommends -y && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

WORKDIR /rails

COPY Gemfile Gemfile.lock ./

RUN bundle config set without 'development' && \
    bundle config set deployment 'false' && \
    bundle install --jobs 4 --retry 3
