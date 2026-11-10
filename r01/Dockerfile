FROM --platform=linux/amd64 ghcr.io/8mo10dance/ruby:3.2.2

COPY apt-packages .

RUN sed -i \
      's|http://deb.debian.org/debian-security|https://archive.debian.org/debian-security|g' \
      /etc/apt/sources.list && \
    apt-get -o Acquire::Check-Valid-Until=false update -qq && \
    xargs -a apt-packages apt-get install --no-install-recommends -y && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

WORKDIR /rails

COPY Gemfile Gemfile.lock ./

RUN bundle config set without 'development' && \
    bundle config set deployment 'false' && \
    bundle install --jobs 4 --retry 3
