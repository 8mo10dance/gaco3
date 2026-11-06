# Rails アプリケーション

Docker Compose で動作する Rails アプリケーションです。ユーザーの登録と画像のアップロードができます。

## 必要な環境

- Docker（Docker Compose を含む）
- ホスト側のポート `3000` と `4566` が利用できること

Ruby 2.7.8 と Rails 6.0 系はコンテナ内で動作するため、ホストへの Ruby のインストールは不要です。DB は SQLite、画像保存には LocalStack の S3 を使用します。

## 初回セットアップ

この README がある `rails` ディレクトリで実行します。

```bash
# イメージのビルドと gem のインストール
docker compose build rails

# DB の準備
docker compose run --rm rails bundle exec rails db:prepare

# LocalStack の起動と画像保存用バケットの作成
docker compose up -d localstack
docker compose exec localstack awslocal s3 mb s3://mybucket --region ap-northeast-1

# Rails の起動
docker compose up -d rails
```

バケット作成は LocalStack の起動準備が完了してから実行してください。状態は `docker compose ps` で確認できます。

## アクセス先

- トップページ: <http://localhost:3000>
- ユーザー一覧・画像アップロード: <http://localhost:3000/users>

## 普段の操作

```bash
# 起動
docker compose up -d

# Rails のログ確認（Ctrl+C でログ表示を終了）
docker compose logs -f rails

# 停止・コンテナの削除
docker compose down
```

SQLite の DB はホスト側の `db/` に保存されます。gem は Docker イメージのビルド時にインストールされます。`Gemfile` または `Gemfile.lock` を変更した場合は、`docker compose build rails` で再ビルドし、`docker compose up -d rails` でコンテナを更新してください。

LocalStack のデータ永続化は設定されていません。コンテナを作り直した場合は、初回セットアップのバケット作成コマンドを再実行してください。以前アップロードした画像も失われるため、必要に応じて再アップロードします。

## テスト

初回セットアップ後、次のコマンドでテスト用 DB の準備と RSpec の実行ができます。画像アップロードを扱うテストのため、LocalStack と `mybucket` も準備してください。

```bash
docker compose run --rm -e RAILS_ENV=test rails bundle exec rails db:prepare
docker compose run --rm -e RAILS_ENV=test rails bundle exec rspec
```
