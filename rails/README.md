# Rails アプリケーション

Docker Compose で動作する Rails アプリケーションです。ユーザーの登録と画像のアップロードができます。

## 必要な環境

- Docker（Docker Compose を含む）
- ホスト側のポート `3000` と `4566` が利用できること

Ruby 2.7.8 と Rails 6.0 系はコンテナ内で動作するため、ホストへの Ruby のインストールは不要です。DB は SQLite、画像保存には Floci の S3 を使用します。

## 初回セットアップ

この README がある `rails` ディレクトリで実行します。

```bash
# イメージのビルドと gem のインストール
docker compose build rails

# DB の準備
docker compose run --rm rails bundle exec rails db:prepare

# Floci の起動と画像保存用バケットの作成
docker compose up -d floci
docker compose run --rm rails bundle exec rails runner 'Aws::S3::Client.new.create_bucket(bucket: "mybucket", object_ownership: "BucketOwnerPreferred", create_bucket_configuration: { location_constraint: "ap-northeast-1" })'

# Rails の起動
docker compose up -d rails
```

バケット作成は Floci の起動準備が完了してから実行してください。状態は `docker compose ps` で確認できます。

画像は `public-read` ACL で保存するため、バケットの ACL を `BucketOwnerPreferred` で有効にします。作成済みのバケットで `The bucket does not allow ACLs` が出る場合は、次のコマンドで設定を変更してください。

```bash
docker compose run --rm rails bundle exec rails runner 'Aws::S3::Client.new.put_bucket_ownership_controls(bucket: "mybucket", ownership_controls: { rules: [{ object_ownership: "BucketOwnerPreferred" }] })'
```

LocalStack から切り替える場合は、先に `docker stop rails-localstack-1`（既定のコンテナ名の場合） で旧コンテナを停止してポート `4566` を解放してください。既存の画像データは移行されません。

S3 の接続先は `http://localhost.floci.io:4566` です。コンテナ内では Compose のネットワークエイリアス、ブラウザでは Floci の公開 DNS（`127.0.0.1`）を使って同じ URL にアクセスします。

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

Floci のデータ永続化は設定されていません。コンテナを作り直した場合は、初回セットアップのバケット作成コマンドを再実行してください。以前アップロードした画像も失われるため、必要に応じて再アップロードします。

## テスト

初回セットアップ後、次のコマンドでテスト用 DB の準備と RSpec の実行ができます。画像アップロードを扱うテストのため、Floci と `mybucket` も準備してください。

```bash
docker compose run --rm -e RAILS_ENV=test rails bundle exec rails db:prepare
docker compose run --rm -e RAILS_ENV=test rails bundle exec rspec
```
