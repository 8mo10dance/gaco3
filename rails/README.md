# Rails アプリケーション

Terraform の Docker provider で起動する Rails アプリケーションです。ユーザーの登録と画像のアップロードができます。

## 必要な環境

- Docker
- Terraform 1.5 以上
- ホスト側のポート `3000` と `4566` が利用できること

Ruby 2.7.8 と Rails 6.0 系はコンテナ内で動作するため、ホストへの Ruby のインストールは不要です。DB は SQLite、画像保存には Floci の S3 を使用します。

## 初回セットアップ

この README がある `rails` ディレクトリで実行します。

```bash
# Docker Desktop を使う場合（Linux の通常の Docker では不要）
export DOCKER_CONTEXT=desktop-linux

# provider のインストールと、イメージのビルド・コンテナの起動
terraform init
terraform apply

# DB の準備
docker exec rails-app bundle exec rails db:prepare

# 画像保存用バケットの作成
docker exec rails-app bundle exec rails runner 'Aws::S3::Client.new.create_bucket(bucket: "mybucket", object_ownership: "BucketOwnerPreferred", create_bucket_configuration: { location_constraint: "ap-northeast-1" })'
```

バケット作成は Floci の起動準備が完了してから実行してください。起動状況は `docker ps`、ログは `docker logs rails-floci` で確認できます。

画像は `public-read` ACL で保存するため、バケットの ACL を `BucketOwnerPreferred` で有効にします。作成済みのバケットで `The bucket does not allow ACLs` が出る場合は、次のコマンドで設定を変更してください。

```bash
docker exec rails-app bundle exec rails runner 'Aws::S3::Client.new.put_bucket_ownership_controls(bucket: "mybucket", ownership_controls: { rules: [{ object_ownership: "BucketOwnerPreferred" }] })'
```

Compose から切り替える場合は、`terraform apply` の前に `docker stop rails-rails-1 rails-floci-1` で既存コンテナを停止してポートを解放してください（既定のコンテナ名の場合）。旧 LocalStack が起動中なら `docker stop rails-localstack-1` も実行します。既存の画像データは新しい Floci コンテナに移行されません。

S3 の接続先は `http://localhost.floci.io:4566` です。コンテナ内では Docker のネットワークエイリアス、ブラウザでは Floci の公開 DNS（`127.0.0.1`）を使って同じ URL にアクセスします。

## アクセス先

- トップページ: <http://localhost:3000>
- ユーザー一覧・画像アップロード: <http://localhost:3000/users>

## 普段の操作

```bash
# 起動・設定変更の反映
terraform apply

# Rails のログ確認（Ctrl+C でログ表示を終了）
docker logs -f rails-app

# 停止・Terraform 管理のコンテナとネットワークの削除
terraform destroy
```

SQLite の DB はホスト側の `db/` に保存されます。gem は Docker イメージのビルド時にインストールされます。`Gemfile` または `Gemfile.lock` を変更した場合は、`terraform apply` で再ビルドとコンテナの更新が行われます。アプリケーションコードはバインドマウントされます。

Floci のデータ永続化は設定されていません。コンテナを作り直した場合は、初回セットアップのバケット作成コマンドを再実行してください。以前アップロードした画像も失われるため、必要に応じて再アップロードします。

## テスト

初回セットアップ後、次のコマンドでテスト用 DB の準備と RSpec の実行ができます。画像アップロードを扱うテストのため、Floci と `mybucket` も準備してください。

```bash
docker exec -e RAILS_ENV=test rails-app bundle exec rails db:prepare
docker exec -e RAILS_ENV=test rails-app bundle exec rspec
```

Terraform の状態はローカルの `terraform.tfstate` に保存されます。このファイルは Git 管理対象外です。作成したリソースを管理するため、削除せず保持してください。
