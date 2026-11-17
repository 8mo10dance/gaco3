# 演習 #2：ECR認証に必要なIAM権限の不足

**難易度：★★☆☆☆｜目安：5分**

## 状況

EC2にはインスタンスプロファイルが正しく関連付けられており、IAMロールも設定済み。

```text
EC2
 └── exercise-02-ec2-profile
      └── exercise-02-ec2-role
           └── exercise-02-ecr-read
```

それでも`user_data`からECR認証に失敗する。

## 調査ログ

※ログ、ARN、IDは演習用の架空の例。

```text
An error occurred (AccessDeniedException)
when calling the GetAuthorizationToken operation:

User: arn:aws:sts::347408264688:
assumed-role/exercise-02-ec2-role/i-0123456789abcdef0
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
  "Account": "347408264688",
  "Arn": "arn:aws:sts::347408264688:assumed-role/exercise-02-ec2-role/i-0123456789abcdef0"
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
      "Resource": "arn:aws:ecr:ap-northeast-1:347408264688:repository/exercise-02-nginx"
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
  347408264688.dkr.ecr.ap-northeast-1.amazonaws.com
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


## 実験環境

構築・調査・コンソールでの修正・削除は [README](README.md) を参照してください。
STS と ECR ログインは EC2 上で実行し、管理用の IAM 操作はローカルで実行します。
ログや ID は期待結果の例です。実際のインスタンス ID に置き換えてください。
