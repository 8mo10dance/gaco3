# Ruby 2.7 / Rails 6.0 の検証環境を作成する (Without Webpacker)

Ruby 2.7 / Rails 6.0 の検証環境を作成する。

Webpacker は使わない。それ以外はデフォルトの設定を使う。

1. Rails アプリケーション作成用の Docker 環境を作る
    
    rails new するだけの Docker 環境を作る。
    
    ホストに直接入れてもいいが、古いバージョンの Ruby / Rails だと入らなかったりするので、 Docker を使うほうがおすすめ。
    
    ```yaml
    services:
      ruby:
        image: ruby:2.7.8
        working_dir: /ruby
        volumes:
          - .:/ruby
          - bundle:/usr/local/bundle
    
    volumes:
      bundle:
    ```
    
    ```yaml
    version: '4'
    
    interaction:
      bash:
        service: ruby
        command: bash
    ```
    
2. Rails インストール
    
    先ほどの docker-compose.yml とかと同じディレクトリに Gemfile を作る。
    
    ```ruby
    # frozen_string_literal: true
    
    source "https://rubygems.org"
    
    git_source(:github) {|repo_name| "https://github.com/#{repo_name}" }
    
    gem "rails", "~> 6.0.0"
    ```
    
    `dip bash` で Docker コンテナに入り、そこで `bundle install` する。
    
3. Rails アプリケーション作成
    
    `dip bash` して Docker コンテナに入り、 `rails new myapp --skip-webpack-install` する。
    
    ffi のエラーが出るかもしれないが、Rails アプリケーション自体は作られているので、問題はない。
    
    なお、ここでは Webpacker は使わない想定なので `--skip-webpack-install` しているが、なぜか Gemfile には webpacker が入っている。不要＆ Rails 立ち上げ時にエラーになるので、消しておく。
    
4. Rails アプリケーション用の Docker 環境を作成する
    
    ```docker
    FROM ruby:2.7.8
    
    WORKDIR /rails
    
    # bundle install 時の ffi-1.17.1-x86_64-linux-musl のエラーのため
    RUN gem update --system 3.3.22
    
    EXPOSE 3000
    CMD bash -c "rm -f tmp/pids/server.pid && bundle exec rails s -b 0.0.0.0"
    ```
    
    ```yaml
    services:
      rails:
        build:
          context: .
        image: myapp:1.0.0
        volumes:
          - .:/rails
          - bundle:/usr/local/bundle
        ports:
          - '3000:3000'
    
    volumes:
      bundle:
    ```
    
    ```yaml
    version: '4'
    
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
    
5. Webpacker を使わずに JavaScript を読み込む
    
    デフォルトでは Webpacker でビルドした JavaScript ファイルを読み込むようになっている。これを Webpacker を使わない形に変更する。
    
    まず、レイアウトの `app/views/layouts/application.html.erb` の `javascript_pack_tag` の部分を書き換える。
    
    ```html
    <!DOCTYPE html>
    <html>
      <head>
        <title>R01</title>
        <%= csrf_meta_tags %>
        <%= csp_meta_tag %>
    
        <%= stylesheet_link_tag 'application', media: 'all', 'data-turbolinks-track': 'reload' %>
        <#%= javascript_pack_tag 'application', 'data-turbolinks-track': 'reload' %>
        <%= javascript_include_tag 'application', 'data-turbolinks-track': 'reload' %>
      </head>
    
      <body>
        <%= yield %>
      </body>
    </html>
    ```
    
    JavaScript ファイルを以下の内容で作成する。
    
    ```jsx
    document.addEventListener('DOMContentLoaded', () => {
      console.log("hoge")
    })
    ```
    
    これだけだと `assets/javascripts` 下のファイルがプリコンパイル対象になっていないため、プリコンパイル対象に追加する。
    
    ```jsx
    //= link_tree ../images
    //= link_tree ../javascripts .js
    //= link_directory ../stylesheets .css
    ```
    
    link_directory だと javascripts 直下のファイルしかプリコンパイル対象にならないので、再帰的にすべてのファイルをプリコンパイル対象にするように link_tree を使う。