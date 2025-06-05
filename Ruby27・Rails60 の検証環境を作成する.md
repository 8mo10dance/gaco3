# Ruby 2.7 / Rails 6.0 の検証環境を作成する

Ruby 2.7 / Rails 6.0 の検証環境を作成する。

Webpacker は使わない。また minitest ではなく rspec を使う。

## 1. Rails アプリケーション作成用の Docker 環境を作る

rails new するだけの Docker 環境を作る。

ホストに直接入れてもいいが、古いバージョンの Ruby / Rails だと入らなかったりするので、 Docker を使うほうがおすすめ。

[Rails アプリケーション作成用の環境構築](./Rails%20アプリケーション作成用の環境構築.md) を参照のこと。
ただし、Gemfile には以下のように記述する。

```ruby
# Gemfile
# frozen_string_literal: true

source "https://rubygems.org"

git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }

gem "rails", "~> 6.0.0"

# bundle install するときに
# `uninitialized constant ActiveSupport::LoggerThreadSafeLevel::Logger`
# のエラーが出るため
# See: https://zenn.dev/84san/scraps/0f612b92969e99
gem "concurrent-ruby", "1.3.4"
```

## 2. Rails アプリケーション作成

`docker compose run --rm ruby bash` して Docker コンテナに入り、 `rails new myapp --skip-javascript --skip-test` する。

ffi のエラーが出るかもしれないが、Rails アプリケーション自体は作られているので、問題はない。

また、concurrent-ruby のバージョンを `1.3.4` に固定する必要がある。
詳細は https://zenn.dev/84san/scraps/0f612b92969e99 を参照のこと。

## 3. Rails アプリケーション用の Docker 環境を作成する

```docker
# Dockerfile
FROM ruby:2.7.8

WORKDIR /rails

# bundle install 時の ffi-1.17.1-x86_64-linux-musl のエラーのため
RUN gem update --system 3.3.22

EXPOSE 3000
CMD bash -c "rm -f tmp/pids/server.pid && bundle exec rails s -b 0.0.0.0"
```

```yaml
# docker-compose.yml
services:
  rails:
    build:
      context: .
    image: myapp:1.0.0
    volumes:
      - .:/rails
      - bundle:/usr/local/bundle
    ports:
      - "3000:3000"

volumes:
  bundle:
```

```yaml
# dip.yml
version: "4"

interaction:
  bundle:
    service: rails
    command: bundle
  rails:
    service: rails
    command: bundle exec rails
    subcommands:
      s:
        command: bundle exec rails s -b 0.0.0.0
        compose:
          run_options: [service-ports]

provision:
  - dip bundle install
```

`dip provision` して `dip up` すると Rails が立ち上がる。

## 4. RSpec をインストールする

```ruby
# Gemfile
group :development, :test do
  gem "rspec-rails"
end
```

以下を実行する。

```bash
dip bundle install
dip rails g rspec:install
```
