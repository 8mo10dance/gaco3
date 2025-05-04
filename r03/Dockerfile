FROM ubuntu:latest

RUN apt-get update && \
    apt-get install -y curl gnupg2 build-essential libpq-dev libssl-dev libreadline-dev zlib1g-dev nodejs npm ruby-dev libyaml-dev

WORKDIR /myapp/backend
COPY backend/Gemfile backend/Gemfile.lock ./
RUN gem install bundler && \
    bundle install

EXPOSE 3000

CMD bash -c "rm -f tmp/pids/server.pid && bin/rails s -b 0.0.0.0"