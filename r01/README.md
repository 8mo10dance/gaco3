# r01の動かし方

```bash
$ dip provision
$ dip up -d
```

## Floci の S3 を扱う方法

1. AWS CLI をインストールする

2. Floci 用のプロファイルを作成する
  ```bash
  $ aws configure --profile floci
  AWS Access Key ID [None]: test
  AWS Secret Access Key [None]: test
  Default region name [None]: ap-northeast-1
  Default output format [None]: json
  ```

3. S3 をコマンドで操作する
  例えば、バケット一覧を取得する場合、以下のコマンドで取得できる。
  ```bash
  $ aws s3 ls --endpoint-url=http://localhost:4566 --profile floci
  ```

## Floci にファイルをアップロードできたかの確認

以下のコマンドでアップロードしたファイルの一覧を取得できる
```
$ aws s3 ls --endpoint-url=http://localhost:4566 --profile floci s3://microposts --recursive
```

# Lambda の実行方法

```bash
$ aws lambda --endpoint-url=http://localhost:4566 --profile floci invoke --function-name my_lambda_function result.log
```

## Playwright E2E テスト

```bash
# 依存関係インストール
$ cd e2e
$ npm install

# ブラウザのインストール
$ npx playwright install

# システム依存ライブラリのインストール
$ npx playwright install-deps

# 別ターミナルで r01 を起動後に実行
$ npm test
```

必要に応じて接続先は `PLAYWRIGHT_BASE_URL` で変更できます。
