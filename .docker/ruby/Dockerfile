ARG RUBY_VERSION=3.2.0
ARG DEBIAN_VERSION=bullseye
ARG BUNDLER_VERSION

FROM ruby:${RUBY_VERSION}-slim-${DEBIAN_VERSION}

RUN apt-get update && \
    apt-get install -y --no-install-recommends make gcc && \
    rm -rf /var/lib/apt/lists/*

RUN if [ -n "$BUNDLER_VERSION" ]; then \
      gem install bundler:"$BUNDLER_VERSION"; \
    fi

CMD ["/usr/bin/bash"]
