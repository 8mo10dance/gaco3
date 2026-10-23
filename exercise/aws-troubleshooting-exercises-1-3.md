# AWSトラブルシューティング演習ノート

EC2 / IAM / インスタンスプロファイル / ECR / user_data

## 目次

1. 演習 #1：インスタンスプロファイルの関連付け忘れ
2. 演習 #2：ECR認証に必要なIAM権限の不足
3. 演習 #3：環境変数による認証情報の上書き
4. 学習内容の総まとめ

---

# 演習 #1：インスタンスプロファイルの関連付け忘れ

**難易度：★☆☆☆☆｜目安：5分**

## 状況

EC2（Amazon Linux 2023）起動時に、`user_data`でECRからDockerイメージをpullしてコンテナを起動したい。

構成：

```text
EC2
 ├── user_data
 │    ├── Docker起動
 │    ├── ECRログイン
 │    ├── docker pull
 │    └── docker run
 │
 └── IAMロール: EC2ECRRole
      └── AmazonEC2ContainerRegistryReadOnly
```

しかし、起動後にコンテナが動いていない。

## 調査ログ

※ログ、ARN、IDは演習用の架空の例。

`/var/log/cloud-init-output.log`

```text
+ aws ecr get-login-password --region ap-northeast-1

Unable to locate credentials.
You can configure credentials by running "aws configure".

Error: Cannot perform an interactive login from a non TTY device
```

IAMロールの存在を確認：

```bash
aws iam get-role --role-name EC2ECRRole
```

```json
{
  "Role": {
    "RoleName": "EC2ECRRole",
    "Arn": "arn:aws:iam::123456789012:role/EC2ECRRole"
  }
}
```

EC2に関連付けられたインスタンスプロファイルを確認：

```bash
aws ec2 describe-instances \
  --instance-ids i-0123456789abcdef0 \
  --query 'Reservations[].Instances[].IamInstanceProfile'
```

```json
[]
```

## 問題

**Q1.** IAMロールとECRの読み取り権限が存在するのに、なぜ認証情報を取得できないのか？

**Q2.** IAMロールとインスタンスプロファイルは何が違うのか？

**Q3.** どうすればEC2からIAMロールを使用できるようになるか？

## 模範解答

### 原因

**EC2にインスタンスプロファイルが関連付けられていない。**

IAMロールが存在しても、EC2がそのロールを使用できるとは限らない。

```text
EC2
  │
  ▼
インスタンスプロファイル
  │
  ▼
IAMロール
  │
  ▼
IAMポリシー
```

IAMロールはAWSへのアクセス権限を持つ主体であり、インスタンスプロファイルはIAMロールをEC2に渡すためのリソース。

### 対処方法

インスタンスプロファイルが存在しない場合、作成してIAMロールを追加する。

```bash
aws iam create-instance-profile \
  --instance-profile-name EC2ECRRole

aws iam add-role-to-instance-profile \
  --instance-profile-name EC2ECRRole \
  --role-name EC2ECRRole
```

EC2に関連付ける。

```bash
aws ec2 associate-iam-instance-profile \
  --instance-id i-0123456789abcdef0 \
  --iam-instance-profile Name=EC2ECRRole
```

※適切な管理権限を持つ環境で実行する。IAMロールの信頼ポリシーにはEC2がそのロールを引き受けられる設定も必要。

### 切り分け

EC2上で実行：

```bash
aws sts get-caller-identity
```

期待する結果：

```json
{
  "Account": "123456789012",
  "Arn": "arn:aws:sts::123456789012:assumed-role/EC2ECRRole/i-0123456789abcdef0"
}
```

これでIAMロールの認証情報を使用できていることが確認できる。

### 補足：複数のEC2で共有できる？

**同じインスタンスプロファイルを複数のEC2に関連付けることは可能。**

- EC2に同時に関連付けられるインスタンスプロファイルは1つ。
- 1つのインスタンスプロファイルに含められるIAMロールは1つ。
- 同じインスタンスプロファイルを複数EC2で共有できる。
- インスタンスプロファイルごとに別のIAMロールを用意する必要はない。

また、各EC2はIMDSを通じて、自分のインスタンスに対して発行された一時認証情報を取得する。

### AWS公式ドキュメント

- [Amazon EC2のIAMロール](https://docs.aws.amazon.com/ja_jp/AWSEC2/latest/UserGuide/iam-roles-for-amazon-ec2.html)
- [インスタンスプロファイルの使用](https://docs.aws.amazon.com/ja_jp/IAM/latest/UserGuide/id_roles_use_switch-role-ec2_instance-profiles.html)

---

# 演習 #2：ECR認証に必要なIAM権限の不足

**難易度：★★☆☆☆｜目安：5分**

## 状況

EC2にはインスタンスプロファイルが正しく関連付けられており、IAMロールも設定済み。

```text
EC2
 └── AppProfile
      └── AppRole
           └── AppECRPolicy
```

それでも`user_data`からECR認証に失敗する。

## 調査ログ

※ログ、ARN、IDは演習用の架空の例。

```text
An error occurred (AccessDeniedException)
when calling the GetAuthorizationToken operation:

User: arn:aws:sts::123456789012:
assumed-role/AppRole/i-0123456789abcdef0
is not authorized to perform:
ecr:GetAuthorizationToken on resource: *
because no identity-based policy allows
the ecr:GetAuthorizationToken action
```

EC2からSTSを実行：

```bash
aws sts get-caller-identity
```

```json
{
  "Account": "123456789012",
  "Arn": "arn:aws:sts::123456789012:assumed-role/AppRole/i-0123456789abcdef0"
}
```

IAMポリシー：

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer",
        "ecr:BatchCheckLayerAvailability"
      ],
      "Resource": "arn:aws:ecr:ap-northeast-1:123456789012:repository/myapp"
    }
  ]
}
```

## 問題

**Q1.** `get-caller-identity`は成功するのに、ECR認証が失敗するのはなぜか？

**Q2.** IAMポリシーをどう修正すればよいか？

**Q3.** ポリシー修正後、EC2の再起動は必要か？

## 模範解答

### 原因

**`ecr:GetAuthorizationToken`が許可されていない。**

`get-caller-identity`が成功することは、IAMロールの認証情報を使用できていることを示す。

しかし、そのIAMロールがECRの認証トークンを取得できるとは限らない。

つまり、認証と認可の問題は分けて考える必要がある。

### 対処方法

以下のStatementを追加する。

```json
{
  "Effect": "Allow",
  "Action": "ecr:GetAuthorizationToken",
  "Resource": "*"
}
```

`ecr:GetAuthorizationToken`はリポジトリ単位でリソースを指定できないため、`Resource`は`"*"`とする。

ただし、これですべてのリポジトリのイメージをpullできるようになるわけではない。

イメージの取得には、さらに次の権限などが必要。

```text
ecr:BatchGetImage
ecr:GetDownloadUrlForLayer
ecr:BatchCheckLayerAvailability
```

これらは特定のリポジトリに限定できる。

### 切り分け手順

1. `aws sts get-caller-identity`で認証主体を確認。
2. `aws ecr get-login-password`の成功・失敗を確認。
3. IAMロールに付与されたポリシーを確認。
4. `ecr:GetAuthorizationToken`を許可。
5. ECRログインとイメージ取得を再試行。

ECRログインの例：

```bash
aws ecr get-login-password \
  --region ap-northeast-1 |
docker login \
  --username AWS \
  --password-stdin \
  123456789012.dkr.ecr.ap-northeast-1.amazonaws.com
```

### EC2の再起動は必要？

**基本的には不要。**

IAMポリシーの変更は、伝播後に適用される。

ただし、通常の`user_data`は初回起動時だけ実行されるため、失敗した処理の再実行が必要。

### 補足：認証トークンとpull権限

ECRの認証トークンは通常12時間有効。

有効なトークンがすでにDockerに保存されている場合、トークンを新規取得できなくても、必要な権限があればpullできる場合がある。

### AWS公式ドキュメント

- [Amazon ECRのIAMポリシー例](https://docs.aws.amazon.com/ja_jp/AmazonECR/latest/userguide/security_iam_id-based-policy-examples.html)
- [ECRのプライベートレジストリ認証](https://docs.aws.amazon.com/ja_jp/AmazonECR/latest/userguide/registry_auth.html)
- [ECRからイメージを取得する](https://docs.aws.amazon.com/AmazonECR/latest/userguide/docker-pull-ecr-image.html)

---

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

---

# 学習内容の総まとめ

## 3つの障害の比較

| 演習 | エラー | 根本原因 |
|---|---|---|
| #1 | `Unable to locate credentials` | インスタンスプロファイル未設定 |
| #2 | `AccessDeniedException` | ECR操作のIAM権限不足 |
| #3 | `UnrecognizedClientException` | 古い認証情報が優先されている |

## AWS認証トラブルの基本的な切り分け

### Step 1：IAMロールを使えているか？

```bash
aws sts get-caller-identity
```

失敗した場合は、まず認証情報の取得元を確認する。

```bash
aws configure list
```

### Step 2：EC2にプロファイルがあるか？

管理権限のあるAWS CLI環境から確認する。

```bash
aws ec2 describe-instances \
  --instance-ids <INSTANCE_ID> \
  --query 'Reservations[].Instances[].IamInstanceProfile'
```

### Step 3：IAMポリシーで操作が許可されているか？

認証主体が正しくても、実行するAWS APIの権限がなければ`AccessDenied`になる。

ECR認証の場合は特に以下を確認する。

```text
ecr:GetAuthorizationToken
```

### Step 4：ECRのログインとpullを個別に確認

ログインの成功とイメージ取得の成功は別。

```text
AWS CLIの認証
   ↓
ecr:GetAuthorizationToken
   ↓
docker login
   ↓
ecr:BatchGetImage など
   ↓
docker pull
```

### Step 5：user_data特有の問題を確認

- 実行ユーザーは通常`root`。
- SSHセッションと環境変数が異なることがある。
- `cloud-init-output.log`でエラーを確認する。
- `user_data`は通常初回起動時に実行される。
- IAMポリシーを変更しても、失敗したスクリプトが自動再実行されるとは限らない。

## 最重要ポイント

**AWS認証の障害は、次の3つを分けて考える。**

1. **認証情報を取得できているか？**
2. **意図したIAMロールの認証情報が使われているか？**
3. **そのIAMロールに必要な操作権限があるか？**

この3つを順番に確認するだけでも、原因の切り分けが大幅に進む。

---

*AWSトラブルシューティング演習 #1〜#3 復習ノート*