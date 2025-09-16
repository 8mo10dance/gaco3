# Rails アプリケーション作成用の環境構築

Dagger shell を使って `rails new` する。

1. Dockerfile を作成する

```Dockerfile:Dockerfile
ARG RUBY_VERSION

FROM ruby:$RUBY_VERSION

WORKDIR /ruby

# bundle install 時の ffi-1.17.1-x86_64-linux-musl のエラーのため
RUN gem update --system 3.3.22 && \
    gem install bundler

COPY Gemfile Gemfile.lock .

RUN bundle install

CMD ["/usr/bin/bash"]
```

2. Gemfile を作成する

```ruby:Gemfile
# frozen_string_literal: true

source "https://rubygems.org"

gem "rails", "~> 6.0.0" # 適宜書き換える

# bundle install するときに
# `uninitialized constant ActiveSupport::LoggerThreadSafeLevel::Logger`
# のエラーが出るため
# See: https://zenn.dev/84san/scraps/0f612b92969e99
gem "concurrent-ruby", "1.3.4"
```

とりあえず Gemfile.lock も作っておく必要があるので、作っておく
```bash
touch Gemfile.lock
```

3. rails new するための dagger スクリプトを作成する

```shell:dagger.sh
#!/usr/bin/env bash

set -eu

RUBY_VERSION=${RUBY_VERSION:-}
APP_NAME=${APP_NAME:-myapp}
RAILS_NEW_OPTIONS=${RAILS_NEW_OPTIONS:-}

echo "Ruby Version: ${RUBY_VERSION}"
echo "To run: rails new ${APP_NAME} ${RAILS_NEW_OPTIONS}"

dagger shell <<EOF
container |
  build . --build-args RUBY_VERSION=${RUBY_VERSION} |
  with-exec -- rails new /ruby/${APP_NAME} ${RAILS_NEW_OPTIONS} |
  directory /ruby/${APP_NAME} |
  export ./${APP_NAME}
EOF
```

```shell:.envrc
export RUBY_VERSION=2.7.8
export RAILS_NEW_OPTIONS='--skip-javascript --skip-test'
```

4. 以下のコマンドを実行して、Rails アプリケーションを作成する。

```bash
./dagger.sh
```
