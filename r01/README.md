# r01の動かし方

```bash
$ dip provison
$ dip up -d
```

## LocalStack の S3 を扱う方法

1. AWS CLI をインストールする

2. LocalStack 用のプロファイルを作成する
  ```bash
  $ aws configure --profile localstack
  AWS Access Key ID [None]: test
  AWS Secret Access Key [None]: test
  Default region name [None]: ap-northeast-1
  Default output format [None]: json

3. S3 をコマンドで操作する
  例えば、バケット一覧を取得する場合、以下のコマンドで取得できる。
  ```bash
  $ aws s3 ls --endpoint-url=http://localhost:4566 --profile localstack
  ```
