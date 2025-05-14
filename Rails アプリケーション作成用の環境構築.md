# Rails アプリケーション作成用の環境構築

`rails new` するための Docker コンテナを作成する。

以下のファイルを作成する。

```Dockerfile:Dockerfile
ARG RUBY_VERSION

FROM ruby:$RUBY_VERSION

WORKDIR /ruby

# bundle install 時の ffi-1.17.1-x86_64-linux-musl のエラーのため
RUN gem update --system 3.3.22 && \
    gem install bundler

CMD ["/usr/bin/bash"]
```

```yaml:docker-compose.yml
services:
  ruby:
    build:
      context: .
      dockerfile: ./Dockerfile
      args:
        - RUBY_VERSION=${RUBY_VERSION}
    volumes:
      - .:/ruby
      - bundle:/usr/local/bundle

volumes:
  bundle:
```

```text:.env
RUBY_VERSION=2.7.8 # 適宜指定する
```

以下のコマンドを実行して、Rails アプリケーションを作成する。

```bash
docker compose build
docker compose run --rm ruby bash
> bundle init
```

Gemfile が生成されるので、`# gem "rails"` のコメントアウトを外して `bundle install` する。
