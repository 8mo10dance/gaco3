FROM ruby:3.2.0-slim-buster

WORKDIR /rails

RUN apt-get update && \
    apt-get install -y --no-install-recommends make=4.2.1-1.2 gcc=4:8.3.0-1 && \
    rm -rf /var/lib/apt/lists/*

CMD ["bash", "-c", "rm -f tmp/pids/server.pid && bundle exec rails s -b 0.0.0.0"]
