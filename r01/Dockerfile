FROM ghcr.io/8mo10dance/ruby:3.2.0

RUN apt-get update && \
    apt-get install -y \
      libmariadb3 \
      default-libmysqlclient-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /rails