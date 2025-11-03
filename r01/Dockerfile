FROM ghcr.io/8mo10dance/ruby:3.2.0

COPY apt-packages .

RUN apt-get update -qq && \
    xargs -a apt-packages apt-get install --no-install-recommends -y && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

WORKDIR /rails
