# 演習 #3：環境変数による認証情報の上書き

**難易度：★★★☆☆｜目安：5分**

## 状況

EC2には`AppRole`が関連付けられており、ECR読み取り権限も正しく設定されている。

しかし、`user_data`からECRにアクセスすると失敗する。

**SSHでログインして同じコマンドを実行すると成功する。**

## user_data

```bash
#!/bin/bash
set -euo pipefail

dnf install -y docker
systemctl enable --now docker

source /opt/myapp/deploy.env

aws ecr get-login-password \
  --region ap-northeast-1 |
docker login \
  --username AWS \
  --password-stdin \
  123456789012.dkr.ecr.ap-northeast-1.amazonaws.com

docker pull \
  123456789012.dkr.ecr.ap-northeast-1.amazonaws.com/myapp:latest

docker run -d -p 80:8080 \
  123456789012.dkr.ecr.ap-northeast-1.amazonaws.com/myapp:latest
```

## 調査ログ

※ログと認証情報は演習用の架空の例。

```text
An error occurred (UnrecognizedClientException)
when calling the GetAuthorizationToken operation:

The security token included in the request is invalid.

Error: Cannot perform an interactive login from a non TTY device
```

SSHから確認：

```bash
aws sts get-caller-identity
```

```json
{
  "Account": "123456789012",
  "Arn": "arn:aws:sts::123456789012:assumed-role/AppRole/i-0123456789abcdef0"
}
```

SSHではECRログインも成功した。

`/opt/myapp/deploy.env`の内容：

```bash
export APP_ENV=production
export AWS_DEFAULT_REGION=ap-northeast-1

export AWS_ACCESS_KEY_ID=AKIAEXAMPLEOLDKEY
export AWS_SECRET_ACCESS_KEY=EXAMPLE_OLD_SECRET_KEY
```

## 問題

**Q1.** なぜSSHからは成功するのに、`user_data`からは失敗するのか？

**Q2.** IAMロールの認証情報が使用されないのはなぜか？

**Q3.** 設定をどのように修正し、どう検証すればよいか？

## 模範解答

### 原因

**環境変数に設定された古いアクセスキーが優先されている。**

問題となる処理：

```bash
source /opt/myapp/deploy.env
```

AWS CLIは複数の場所から認証情報を取得する。

今回関係する優先順位は次のとおり。

```text
環境変数
   ↓
共有認証情報ファイルなど
   ↓
EC2インスタンスプロファイル
```

※AWS CLIの認証情報プロバイダーには、ほかにも複数の種類がある。

`user_data`では`deploy.env`によって環境変数が設定されるため、IAMロールから取得する認証情報が使用されない。

SSHのシェルでは`deploy.env`を読み込んでいないため、IAMロールの認証情報が使用されたと考えられる。

### 対処方法

`deploy.env`から不要な固定アクセスキーの設定を削除する。

```bash
# 削除する設定
export AWS_ACCESS_KEY_ID=...
export AWS_SECRET_ACCESS_KEY=...
```

すでに読み込まれている環境では、必要に応じて解除する。

```bash
unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN
```

### 切り分け手順

AWS CLIがどこから認証情報を取得しているか確認する。

```bash
aws configure list
```

認証主体を確認する。

```bash
aws sts get-caller-identity
```

期待するARN：

```text
arn:aws:sts::123456789012:
assumed-role/AppRole/i-0123456789abcdef0
```

IAMロールを使用していることが確認できたら、ECRログインを再試行する。

### AWS公式ドキュメント

- [AWS CLIの設定と認証情報](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html)
- [AWS CLIの認証情報プロバイダーチェーン](https://docs.aws.amazon.com/cli/latest/userguide/cli-chap-configure.html)
- [EC2のインスタンスメタデータ](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-instance-metadata.html)


## 実験環境

構築・調査・復旧・削除は [README](README.md) を参照してください。ロール名は実験環境では exercise-03-ec2-role です。ログと ID は例です。
