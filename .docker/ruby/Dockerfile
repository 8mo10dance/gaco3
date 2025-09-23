ARG RUBY_VERSION=3.2.0
ARG DEBIAN_VERSION=bullseye

FROM ruby:${RUBY_VERSION}-slim-${DEBIAN_VERSION}

RUN apt-get update && \
    apt-get install -y --no-install-recommends make gcc && \
    rm -rf /var/lib/apt/lists/*

CMD ["/usr/bin/bash"]
