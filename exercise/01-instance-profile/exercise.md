# 演習 #1：インスタンスプロファイルの関連付け忘れ

## 課題内容

**難易度：★☆☆☆☆｜目安：5分**

### 状況

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
 └── IAMロール: exercise-01-ec2-role
      └── AmazonEC2ContainerRegistryReadOnly
```

しかし、起動後にコンテナが動いていない。

### 調査ログ

※ログと出力は期待する結果の例。インスタンスIDはEC2コンソールで確認した実際の値に置き換える。
コマンドの実行場所は次のように区別する。

| 実行場所 | 用途 |
| --- | --- |
| ローカル端末（Terraformを実行したPC） | IAMロールの確認、EC2の関連付け確認、環境の構築 |
| EC2上（SSH接続後のシェル） | cloud-initログの確認、EC2自身の認証情報の確認 |

`default`プロファイルはローカル端末のAWS CLI設定を使用する。EC2上には用意していないため、`--profile default`付きの管理用コマンドはEC2上で実行しない。
SSH接続中にローカルのコマンドを実行する場合は、別のローカル端末を開くか、`exit`でSSH接続を終了する。

**実行場所：EC2上（SSH接続後）**

```bash
sudo cat /var/log/cloud-init-output.log
```

`/var/log/cloud-init-output.log`の出力例：

```text
+ aws ecr get-login-password --region ap-northeast-1

Unable to locate credentials.
You can configure credentials by running "aws configure".

Error: Cannot perform an interactive login from a non TTY device
```

IAMロールの存在を確認：

**実行場所：ローカル端末（Terraformを実行したPC）**

```bash
aws --profile default --region ap-northeast-1 iam get-role --role-name exercise-01-ec2-role
```

```json
{
  "Role": {
    "RoleName": "exercise-01-ec2-role",
    "Arn": "arn:aws:iam::347408264688:role/exercise-01-ec2-role"
  }
}
```

EC2に関連付けられたインスタンスプロファイルを確認：

**実行場所：ローカル端末（Terraformを実行したPC）**

```bash
aws --profile default --region ap-northeast-1 ec2 describe-instances \
  --instance-ids i-0123456789abcdef0 \
  --query 'Reservations[].Instances[].IamInstanceProfile'
```

```json
[]
```

### 問題

**Q1.** IAMロールとECRの読み取り権限が存在するのに、なぜ認証情報を取得できないのか？

**Q2.** IAMロールとインスタンスプロファイルは何が違うのか？

**Q3.** どうすればEC2からIAMロールを使用できるようになるか？

### 模範解答

#### 原因

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

#### 対処方法

この環境では、インスタンスプロファイル`exercise-01-ec2-profile`と、その中のIAMロール`exercise-01-ec2-role`は作成済み。

AWSコンソールでEC2に関連付ける。

1. EC2コンソールで演習用インスタンスを選択する。
2. 「アクション」→「セキュリティ」→「IAMロールを変更」を開く。
3. `exercise-01-ec2-profile`に対応する項目を選択して更新する。

※適切な管理権限を持つ環境で実行する。IAMロールの信頼ポリシーにはEC2がそのロールを引き受けられる設定も必要（この環境では設定済み）。

#### 切り分け

**実行場所：EC2上（SSH接続後）。`--profile default`は指定しない。**

```bash
aws sts get-caller-identity
```

期待する結果：

```json
{
  "Account": "347408264688",
  "Arn": "arn:aws:sts::347408264688:assumed-role/exercise-01-ec2-role/i-0123456789abcdef0"
}
```

これでIAMロールの認証情報を使用できていることが確認できる。

通常の`user_data`は初回起動時のみ実行されるため、失敗したECRログイン以降の処理は手動で再実行する。具体的な手順は[README](README.md#aws-コンソールで修正)を参照。

#### 補足：複数のEC2で共有できる？

**同じインスタンスプロファイルを複数のEC2に関連付けることは可能。**

- EC2に同時に関連付けられるインスタンスプロファイルは1つ。
- 1つのインスタンスプロファイルに含められるIAMロールは1つ。
- 同じインスタンスプロファイルを複数EC2で共有できる。
- インスタンスプロファイルごとに別のIAMロールを用意する必要はない。

また、各EC2はIMDSを通じて、自分のインスタンスに対して発行された一時認証情報を取得する。

#### AWS公式ドキュメント

- [Amazon EC2のIAMロール](https://docs.aws.amazon.com/ja_jp/AWSEC2/latest/UserGuide/iam-roles-for-amazon-ec2.html)
- [インスタンスプロファイルの使用](https://docs.aws.amazon.com/ja_jp/IAM/latest/UserGuide/id_roles_use_switch-role-ec2_instance-profiles.html)

## 実験環境の構築

実 AWS に課金対象のリソースを作成します。
以下の手順は、課題の初期状態を準備するためのものです。

Terraform、AWS CLI、Docker buildx を使用します。AWS の `default` プロファイル、
東京リージョン、許可アカウントは `provider.tf` で指定しています。
EC2 には Amazon Linux 2023 を使用します。

**実行場所：ローカル端末の `exercise/01-instance-profile/` ディレクトリ**

SSH 公開鍵は既定で
`./keys/floci_key.pub` を使用します。

```bash
terraform init
terraform apply
bash push.sh
```

別の鍵を使う場合は `-var='ssh_public_key_path=/path/to/key.pub'` も指定します。
ECR イメージを push する前でも、初回起動は認証情報不足の段階で失敗します。


構築後は EC2 コンソールでインスタンス ID とパブリック IP を確認し、課題の調査に進みます。
SSH 接続と復旧後の確認、環境の削除は [README](README.md) を参照してください。
