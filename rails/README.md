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

# provider のインストールと、イメージのビルド・コンテナの起動・DB とバケットの準備
terraform init
terraform apply
```

画像保存用の `mybucket` と ACL 設定（`BucketOwnerPreferred`）は AWS provider が Floci に作成します。画像は `public-read` ACL で保存します。Terraform はホストの `http://localhost:4566` に接続します。

既存バケットを初めて Terraform 管理に取り込む場合は、`terraform init` 後に次を実行してください。

```bash
terraform import aws_s3_bucket.avatars mybucket
terraform import aws_s3_bucket_ownership_controls.avatars mybucket
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

`terraform destroy` は画像が残っているバケットを削除できません。削除する場合は、先にバケット内の画像を空にしてください。

SQLite の DB はホスト側の `db/` に保存されます。gem は Docker イメージのビルド時にインストールされます。`Gemfile` または `Gemfile.lock` を変更した場合は、`terraform apply` で再ビルドとコンテナの更新が行われます。アプリケーションコードはバインドマウントされます。

開発用 DB は Terraform が `rails db:prepare` で準備します。初回作成時・Rails コンテナの再作成時・`db/migrate/*.rb` または `config/database.yml` の変更時に実行されます。DB ファイルを手動で削除した場合など、再実行が必要なときは次のコマンドを使用してください。

```bash
terraform apply -replace=terraform_data.db_prepare
```

Floci のデータ永続化は設定されていません。コンテナを作り直してバケットが消失した場合は、再度 `terraform apply` してバケットを作成してください。以前アップロードした画像も失われるため、必要に応じて再アップロードします。

## テスト

初回セットアップ後、次のコマンドでテスト用 DB の準備と RSpec の実行ができます。Floci と `mybucket` は `terraform apply` で準備されます。

```bash
docker exec -e RAILS_ENV=test rails-app bundle exec rails db:prepare
docker exec -e RAILS_ENV=test rails-app bundle exec rspec
```

Terraform の状態はローカルの `terraform.tfstate` に保存されます。このファイルは Git 管理対象外です。作成したリソースを管理するため、削除せず保持してください。
