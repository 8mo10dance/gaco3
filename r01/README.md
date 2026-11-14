# r01の動かし方

```bash
$ dip provision
$ dip up -d
```

## Floci の S3 を扱う方法

`dip up -d` で Floci の起動を待って Terraform が S3 の設定を適用し、完了後に Rails が起動する。
設定は `terraform/` で管理し、`microposts` バケット、所有権、公開 ACL の許可、PUT 用 CORS を作成する。
Terraform は Docker で実行するため、ホストへのインストールは不要。

設定変更時は、Floci が起動した状態で以下を実行する。

```bash
$ dip terraform init
$ dip terraform plan
$ dip terraform apply
```

state は `terraform/terraform.tfstate` に保存する（Git 管理対象外）。
Floci のデータを削除した場合も state を使って再適用できる。
既存の初期化スクリプトで作成済みのバケットを引き継ぐ場合は、初回の適用前に以下を実行する。

```bash
$ dip terraform init
$ dip terraform import aws_s3_bucket.microposts microposts
$ dip terraform apply
```

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

## Playwright E2E テスト

[Playwright](https://playwright.dev/) を使用したE2Eテスト。

### 前提条件

- Node.js がインストールされていること
- Railsサーバーが `http://localhost:3000` で起動していること (`dip rails s`)

### セットアップ

依存パッケージとブラウザをインストールする。

```bash
cd e2e
npm install
npx playwright install chromium
```

Playwright のブラウザ実行に必要なOS側の依存ライブラリもインストールする。

```bash
npx playwright install-deps
```

`npx playwright test` 実行時に以下のようなエラーが出る場合は、Chromium の起動に必要な共有ライブラリが不足している。

```text
error while loading shared libraries: libnspr4.so: cannot open shared object file: No such file or directory
```

この場合も `npx playwright install-deps` を実行して依存ライブラリを入れる。

### 実行

```bash
cd e2e
npx playwright test
```

または npm scripts 経由で:

```bash
npm test               # ヘッドレスで実行
npm run test:headed    # ブラウザを表示して実行
npm run test:ui        # Playwright UI モードで実行
```

### 設定

`e2e/playwright.config.js` で設定を管理している。接続先URLは環境変数 `PLAYWRIGHT_BASE_URL` で変更できる（デフォルト: `http://127.0.0.1:3000`）。

```bash
PLAYWRIGHT_BASE_URL=http://staging.example.com npx playwright test
```
