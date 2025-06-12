FROM ruby:3.2.0-slim-bullseye

WORKDIR /rails

RUN apt-get update && \
    apt-get install -y --no-install-recommends make gcc && \
    rm -rf /var/lib/apt/lists/*

CMD ["bash", "-c", "rm -f tmp/pids/server.pid && bundle exec rails s -b 0.0.0.0"]
