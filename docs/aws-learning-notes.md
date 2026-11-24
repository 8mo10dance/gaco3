# AWS 学習メモ

## 1. AWS の学習環境

### AWS Skill Builder / Builder Labs

AWS Skill Builder の Builder Labs では、一時的な AWS 環境を使って実際の AWS コンソールを操作できる。

ただし、自由な Sandbox として使うものではなく、基本的には、

- S3 を構築する
- EC2 を起動する
- VPC を構築する

といった **学習コンテンツに紐づいた環境**。

自分のサービスを自由に構築して長時間動かす用途には向かない。

### 自分で Sandbox を作る

自由に実験するなら、自分の AWS アカウントを Sandbox として使う。

本格的に環境を分離したくなったら AWS Organizations で、

```text
Management Account
└── Sandbox Account
```

のように分けられる。

ただし AWS アカウント自体は、Docker コンテナのように気軽に作成・破棄するものではない。

基本的には Sandbox Account を残しておき、その中のリソースを作成・削除して繰り返し使う。

---

## 2. Terraform を使った AWS 学習

AWS コンソールだけで構築すると、現在の設定を AI に見せたり、Git で管理したりするのが難しい。

そのため、

```text
Terraform
    ↓
AWS
```

を基本にすると扱いやすい。

重要なのは、

> Terraform を学ぶのではなく、Terraform を使って AWS を学ぶ

というスタンス。

Terraform で作った後も AWS コンソールを確認して、

```text
Terraform resource
        ↕
AWS Console
```

の対応を見る。

---

## 3. AWS CLI と Terraform の認証

Terraform は AWS Provider を通して AWS API にアクセスする。

```text
Terraform
   ↓
AWS Provider
   ↓
AWS Credentials
   ↓
AWS API
```

AWS CLI を Homebrew でインストールできる。

```bash
brew install awscli
```

確認：

```bash
aws --version
```

現在は学習のためルートユーザーを使っているが、最終的には IAM Identity Center などへ移行する。

ルートユーザーの Access Key は非常に強い権限を持つため、恒久的には使用しない。

---

## 4. Console → Terraform

AWS コンソールで実験してから Terraform 化することもできる。

Terraform 1.5 以降では `import` block を利用できる。

```hcl
import {
  to = aws_s3_bucket.website
  id = "my-bucket"
}
```

そして、

```bash
terraform plan -generate-config-out=generated.tf
```

とすると、既存リソースから Terraform の `resource` block を生成できる。

ただし、

```bash
terraform plan -generate-config-out=generated.tf
```

だけでは AWS 全体を探索してくれない。

`import` block で、

> どの AWS リソースを Terraform のどの resource として取り込むか

を指定する必要がある。

つまり、

```text
AWS全体をスキャン
      ↓
Terraform完全生成
```

という機能ではない。

---

## 5. Terraform 化の基本フロー

今後は次のようなワークフローを想定する。

```text
Codex
  ↓
Terraform の雛形を作る
  ↓
import
  ↓
terraform plan -generate-config-out
  ↓
既存AWS環境とコードを合わせる
  ↓
terraform plan
  ↓
No changes を確認
  ↓
Floci で変更をローカル検証
  ↓
実AWSに対して terraform plan
  ↓
terraform apply
```

`-generate-config-out` の生成物は完成品というより、

> 現在の AWS 設定を写した下書き

として扱う。

生成された冗長な設定は整理する。

---

## 6. Floci

Floci を使うと、一部 AWS API をローカルでエミュレートできる。

```text
Terraform
   ↓
Floci
   ↓
Local AWS-like environment
```

用途は、

- Terraform の構文確認
- AWS リソース間の参照確認
- S3 などの基本的な動作確認
- ローカル統合テスト

など。

ただし、

```text
Flociで成功
    ≠
AWSでも必ず成功
```

なので、最終確認は実 AWS に対する、

```bash
terraform plan
```

で行う。

---

## 7. S3 静的サイト

最初の実験として S3 に `index.html` を配置し、Static Website Hosting を有効にした。

```text
Browser
   ↓ HTTP
S3 Website Endpoint
   ↓
index.html
```

公開には、

- Static Website Hosting
- Index Document
- Public Access Block
- Bucket Policy
- S3 Object

などが関係する。

Terraform では、それぞれ別 resource になる。

```text
aws_s3_bucket
aws_s3_bucket_website_configuration
aws_s3_bucket_public_access_block
aws_s3_bucket_policy
aws_s3_object
```

そのため、

```hcl
import {
  to = aws_s3_bucket.website
  ...
}
```

だけを import しても、静的サイト全体は Terraform 化されない。

---

## 8. 静的サイトジェネレーター + S3

Astro、Hugo、Jekyll などの静的サイトジェネレーターを使う場合、

```text
Source
  ↓
Static Site Generator
  ↓ build
dist/ or public/
  ↓
S3
```

という構成にする。

Terraform はインフラを管理する。

```text
Terraform
├── S3
├── CloudFront
├── Bucket Policy
└── etc.
```

ビルド成果物は Terraform で1ファイルずつ管理せず、

```bash
aws s3 sync ./dist s3://bucket-name --delete
```

などでデプロイする。

つまり、

```text
Terraform
  → Infrastructure

aws s3 sync
  → Application / Contents
```

と役割を分ける。

---

## 9. CloudFront

S3 の前に CloudFront を置ける。

```text
Browser
   ↓ HTTPS
CloudFront
   ↓
S3
```

CloudFront のドメイン、

```text
https://xxxxxxxx.cloudfront.net
```

は HTTPS でアクセスできる。

独自ドメインを使う場合は ACM で証明書を発行して CloudFront に設定する。

---

## 10. OAC

OAC は **Origin Access Control**。

CloudFront だけが Private S3 にアクセスできるようにする仕組み。

```text
Internet
   ↓
CloudFront
   ↓ OAC
Private S3
```

これにより、

```text
User → CloudFront → S3  ○

User ───────────→ S3  ✕
```

にできる。

CloudFront が S3 へのリクエストを SigV4 で署名し、S3 の Bucket Policy 側で CloudFront からのアクセスだけを許可する。

この場合、S3 Static Website Hosting は不要。

```text
Public S3 Website

Browser
 ↓
S3 Website Endpoint
```

から、

```text
Private S3

Browser
 ↓ HTTPS
CloudFront
 ↓ OAC
S3
```

へ移行できる。

---

## 11. CloudFront と ALB

CloudFront と ALB は役割が違う。

### CloudFront

- CDN
- キャッシュ
- エッジ配信
- S3 配信
- HTTPS
- パスによる Origin 切り替え

### ALB

- アプリケーションサーバーへの負荷分散
- EC2 / ECS へのルーティング
- Health Check
- Host / Path Routing
- TLS 終端

ALB は S3 を直接 Target にできない。

静的サイトだけなら、

```text
CloudFront
   ↓
S3
```

で十分。

Rails などを追加する場合は、

```text
                   ┌→ S3
                   │
Browser → CloudFront
                   │
                   └→ ALB
                        ↓
                   Rails
```

という構成が可能。

例えば、

```text
/*       → S3
/api/*   → ALB → Rails
```

のように振り分けられる。

---

## 12. EC2

まず EC2 上で Docker コンテナを動かすところまで実験した。

最小構成：

```text
Internet
   ↓
EC2 Public IP
   ↓
Docker
   ↓
Web Application
```

EC2 は必ず VPC / Subnet 内に存在する。

ただし最初は AWS が用意している Default VPC / Default Subnet を利用できるため、自分で VPC を構築しなくても実験できる。

```text
Default VPC
└── Default Subnet
     └── EC2
```

---

## 13. Security Group

EC2 のアプリケーションが例えば `8080` で待ち受けている場合、直接公開するなら、

```text
Internet
   ↓ :8080
Security Group
   ↓
EC2 :8080
```

となる。

ALB を追加した場合は、

```text
Internet
   ↓ :80 / :443
ALB
   ↓ :8080
EC2
```

とする。

このとき EC2 の Security Group は、

```text
Port:   8080
Source: ALB Security Group
```

にする。

`0.0.0.0/0` から EC2 の `8080` を許可する必要はなくなる。

結果として、

```text
Internet → EC2:8080   ✕
Internet → ALB → EC2  ○
```

になる。

---

## 14. ECS

ECS = **Elastic Container Service**。

Docker コンテナを AWS 上で管理するサービス。

現在は、

```text
EC2
 ↓
Docker
 ↓
Container
```

として、自分で、

```bash
docker run ...
```

している。

ECS を使うと、

```text
ECS
 ↓
EC2
 ↓
Container
```

となり、コンテナ管理を ECS に任せられる。

ECS の主な概念：

### Cluster

コンテナを動かす論理的なグループ。

### Task Definition

コンテナの設計図。

```text
Docker Image
CPU
Memory
Port
Environment Variables
etc.
```

### Task

Task Definition を実際に起動したもの。

### Service

Task を指定した数だけ維持する。

```text
desired_count = 2

ECS Service
├── Task
└── Task
```

Task が死んだ場合、新しい Task を起動して desired count を維持する。

---

## 15. ECS on EC2 と Fargate

ECS と Fargate は競合するものではない。

```text
             ECS
              │
       ┌──────┴──────┐
       ↓             ↓
      EC2         Fargate
       ↓             ↓
 Container       Container
```

ECS は **コンテナを管理する仕組み**。

Fargate は **コンテナを実際に実行する環境**。

### ECS on EC2

```text
ECS
 ↓
自分のEC2
 ↓
Container
```

EC2 の管理は自分で行う。

### ECS + Fargate

```text
ECS
 ↓
Fargate
 ↓
Container
```

EC2 の管理を AWS に任せられる。

つまり、

> ECS は Docker コンテナの管理者
>
> Fargate は EC2 の代わりになる実行環境

と考えると分かりやすい。

---

## 16. 現在の構成からの発展

現在：

```text
Internet
   ↓
EC2
   ↓
Docker
   ↓
Web Application
```

次に ALB を追加すると、

```text
Internet
   ↓
ALB
   ↓
EC2
   ↓
Docker
   ↓
Web Application
```

その後 Fargate 化すると、

```text
Internet
   ↓
ALB
   ↓
ECS
   ↓
Fargate
   ↓
Web Application
```

Rails + RDS まで進めると、

```text
Internet
   ↓
ALB
   ↓
ECS / Fargate
   ↓
Rails
   ↓
RDS
```

静的フロントエンドも含めるなら、

```text
                         ┌→ Private S3
                         │
Internet → CloudFront ───┤
                         │
                         └→ ALB
                              ↓
                         ECS / Fargate
                              ↓
                            Rails
                              ↓
                             RDS
```

のような構成に発展できる。

---

## 17. 今後の学習順序

現時点では ECS を急いで導入する必要はない。

今の EC2 + Docker から、

```text
1. EC2 + Docker
      ↓
2. Security Group
      ↓
3. ALB
      ↓
4. HTTPS / ACM
      ↓
5. RDS
      ↓
6. CloudWatch
      ↓
7. ECR
      ↓
8. ECS
      ↓
9. Fargate
```

くらいの順で進める。

こうすると、それぞれについて、

> 「何の問題を解決するために、このAWSサービスが必要なのか？」

を実際に体験しながら理解できる。

---

## 18. EC2 から RDS へ接続する手順

### ネットワーク設定

EC2 から RDS へ接続するには、RDS に関連付けたセキュリティグループのインバウンドルールで、EC2 のセキュリティグループからの通信を許可する。

MySQL の例:

| 項目 | 設定値 |
| --- | --- |
| タイプ | MySQL/Aurora |
| プロトコル | TCP |
| ポート | 3306 |
| ソース | EC2 に付与しているセキュリティグループ |

EC2 と RDS は同じ VPC 内に配置するのが基本である。IP アドレスではなく、EC2 のセキュリティグループをソースに指定すると安全に管理できる。

RDS コンソールでは、**RDS → データベース → 対象DB → アクション → EC2 接続をセットアップ** から、接続設定を補助できる。

### RDS エンドポイントの確認場所

AWS コンソールで **RDS → データベース → 対象のDB → 接続とセキュリティ** の順に開く。「エンドポイントとポート」に表示される **エンドポイント** を使う。`https://` は付けない。

```text
example.abcdefghijkl.ap-northeast-1.rds.amazonaws.com
```

### Secrets Manager に認証情報を作成する

AWS コンソールで **Secrets Manager → 新しいシークレットを保存** を開く。シークレットのタイプは **RDS データベースの認証情報** を選び、`username` と `password` を入力して対象の RDS DB インスタンスを選択する。名前を付けて保存する。接続例では、保存された JSON の `username` と `password` を利用する。

作成後、シークレット詳細の **シークレット ARN** をコピーする。IAM ポリシーの `Resource` と EC2 上の `--secret-id` には、末尾のランダムなサフィックスまで含む完全な ARN を指定する。

```text
arn:aws:secretsmanager:ap-northeast-1:123456789012:secret:myapp/rds-credentials-a1B2c3
```

`myapp/rds-credentials` のような名前だけや、末尾サフィックスを省いた ARN ではなく、コンソールに表示された ARN をそのまま使う。

### EC2 の IAM ロールに読み取り権限を追加する

EC2 には IAM ロールを一つだけ関連付ける。新しいロールを追加するのではなく、EC2 にすでに関連付けられているロールへ、対象シークレットだけを読めるインラインポリシーまたは管理ポリシーを追加する。

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "secretsmanager:GetSecretValue",
      "Resource": "arn:aws:secretsmanager:ap-northeast-1:123456789012:secret:myapp/rds-credentials-a1B2c3"
    }
  ]
}
```

シークレットにカスタマー管理 KMS キーを使っている場合は、そのキーに対する復号権限も別途必要になる。

### Amazon Linux 2023 にクライアントをインストールする

Amazon Linux 2023 で `mysql-client` が見つからない場合は、MariaDB クライアントと `jq` をインストールする。

```bash
sudo dnf install -y mariadb105 jq
```

`mariadb105` の `105` は MariaDB 10.5 を表す。RDS に接続するだけならサーバーは不要なので、`mariadb105-server` をインストールする必要はない。`mysql` コマンドとして接続できることを確認する。

```bash
mysql --version
jq --version
```

### EC2 から Secrets Manager の認証情報を確認する

EC2 上で、完全な Secret ARN を環境変数に設定して取得を確認する。以下の確認コマンドはパスワードを表示しない。

```bash
AWS_REGION='ap-northeast-1'
DB_SECRET_ARN='arn:aws:secretsmanager:ap-northeast-1:123456789012:secret:myapp/rds-credentials-a1B2c3'

aws secretsmanager get-secret-value \
  --secret-id "$DB_SECRET_ARN" \
  --region "$AWS_REGION" \
  --query 'SecretString' \
  --output text |
  jq -e '{username: .username, password_present: (.password | type == "string" and length > 0)}'
```

`password_present` が `true` になれば、JSON から `username` と `password` を取得できる。パスワードそのものを画面やログに出力しない。

### defaults-extra-file による安全な MySQL 接続例

パスワードを `mysql` の `-p` 引数に直接渡さない。代わりに、所有者だけが読める一時 option file を作り、`--defaults-extra-file` を最初の引数として渡す。

```bash
set -euo pipefail

AWS_REGION='ap-northeast-1'
DB_SECRET_ARN='arn:aws:secretsmanager:ap-northeast-1:123456789012:secret:myapp/rds-credentials-a1B2c3'
DB_HOST='example.abcdefghijkl.ap-northeast-1.rds.amazonaws.com'

umask 077
MYSQL_DEFAULTS_FILE=$(mktemp)
trap 'rm -f "$MYSQL_DEFAULTS_FILE"' EXIT HUP INT TERM

aws secretsmanager get-secret-value \
  --secret-id "$DB_SECRET_ARN" \
  --region "$AWS_REGION" \
  --query 'SecretString' \
  --output text |
  jq -er --arg host "$DB_HOST" '\
    "[client]", \
    "host=" + $host, \
    "port=3306", \
    "user=" + .username, \
    "password=" + .password \
  ' >"$MYSQL_DEFAULTS_FILE"
chmod 600 "$MYSQL_DEFAULTS_FILE"

mysql --defaults-extra-file="$MYSQL_DEFAULTS_FILE"
```

`umask 077`、`mktemp`、`chmod 600` により一時ファイルは所有者だけが読める。`trap` は接続終了時や割り込み時にファイルを削除する。`--defaults-extra-file` は MySQL のオプション解釈のため、必ず他の MySQL オプションより前に置く。

### user_data を変更したときの反映

EC2 の `user_data` は通常、初回起動時に実行される。既存インスタンスを通常どおり再起動しても再実行されないため、パッケージ追加などの変更は再起動だけでは反映されない。

Terraform で `user_data` の変更時にインスタンスを置き換えるには、`aws_instance` に次を指定する。

```hcl
resource "aws_instance" "app" {
  # ...
  user_data                   = file("user_data.sh")
  user_data_replace_on_change = true
}
```

特定のインスタンスを明示的に作り直して反映する場合は、次のように実行する。

```bash
terraform apply -replace='aws_instance.app'
```

> 注意: シークレット、シェル変数、接続コマンドに含まれるパスワードを共有・記録しない。

## 19. Terraform による AWS インフラ構築

### 1. Terraform のバージョン管理

`required_version` で Terraform 本体のバージョン制約を指定する。

```hcl
# versions.tf
terraform {
  required_version = "~> 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}
```

#### バージョン制約

| 指定 | 許容されるバージョン |
| --- | --- |
| `1.10.0` | 1.10.0 のみ |
| `>= 1.10.0` | 1.10.0 以上 |
| `~> 1.10.0` | 1.10.x |
| `~> 1.10` | 1.10 以上、2.0 未満 |

`required_version` はバージョンを切り替えるものではなく、互換性を保証するための制約である。

### 2. VPC

```hcl
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "main"
  }
}
```

### 3. Subnet

#### パブリックサブネット

```hcl
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "public"
  }
}
```

#### プライベートサブネット

```hcl
resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "private"
  }
}
```

#### Availability Zone の指定

`availability_zone` でサブネットを配置する AZ を指定する。

```hcl
availability_zone = "ap-northeast-1a"
```

利用可能な AZ を動的に取得することもできる。

```hcl
data "aws_availability_zones" "available" {
  state = "available"
}
```

```hcl
availability_zone = data.aws_availability_zones.available.names[0]
```

既存のサブネットの AZ を変更すると、サブネットは再作成される。

#### 複数の AZ にサブネットを作成する

```hcl
resource "aws_subnet" "public" {
  for_each = {
    "ap-northeast-1a" = "10.0.1.0/24"
    "ap-northeast-1c" = "10.0.3.0/24"
  }

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = each.key
}
```

#### map_public_ip_on_launch

サブネット内で起動する EC2 にパブリック IPv4 アドレスを自動的に割り当てるかを指定する。

- `true`: 自動的に割り当てる
- `false`: 自動的に割り当てない

EC2 側で個別に上書きすることもできる。

```hcl
associate_public_ip_address = true
```

パブリックサブネットかどうかを決めるのはルートテーブルであり、`map_public_ip_on_launch` ではない。

### 4. Internet Gateway

VPC とインターネットを接続するためのゲートウェイ。

```hcl
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "main"
  }
}
```

EC2 がインターネットと直接 IPv4 通信するには、以下の条件が必要。

- パブリック IP が割り当てられている
- VPC に Internet Gateway が接続されている
- ルートテーブルに Internet Gateway へのルートが存在する
- Security Group と Network ACL で通信が許可されている

### 5. NAT Gateway

プライベートサブネット内の EC2 が、パブリック IP を持たずにインターネットへアクセスするために使用する。

#### Elastic IP

```hcl
resource "aws_eip" "nat" {
  domain = "vpc"
}
```

#### NAT Gateway の作成

```hcl
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id

  depends_on = [aws_internet_gateway.main]

  tags = {
    Name = "main"
  }
}
```

通常のゾーン単位の Public NAT Gateway はパブリックサブネットに配置する。

通信経路は以下のようになる。

```text
EC2 (Private Subnet)
  |
  v
NAT Gateway (Public Subnet)
  |
  v
Internet Gateway
  |
  v
Internet
```

NAT Gateway は内部から開始した通信とその応答を中継する。インターネット側からの新規接続は受け付けない。

#### depends_on

Terraform はリソースの属性参照から依存関係を自動的に推論する。

```hcl
subnet_id = aws_subnet.public.id
```

この場合、Subnet が作成されてから NAT Gateway が作成される。

一方、NAT Gateway の定義には Internet Gateway への属性参照が存在しないため、Terraform は両者の依存関係を推論できない。

そこで明示的に依存関係を指定する。

```hcl
depends_on = [aws_internet_gateway.main]
```

意味的な依存関係が存在するが、属性の参照関係が存在しない場合に `depends_on` を使用する。

#### Public NAT Gateway と Private NAT Gateway

| 項目 | Public NAT | Private NAT |
| --- | --- | --- |
| インターネット接続 | 可能 | 不可 |
| Elastic IP | 必要 | 不要 |
| IGW への依存 | 推奨 | 不要 |
| 主な用途 | インターネット接続 | VPC 間・オンプレミス接続 |

Private NAT Gateway の定義例：

```hcl
resource "aws_nat_gateway" "private" {
  connectivity_type = "private"
  subnet_id         = aws_subnet.private.id
}
```

#### 注意事項

- NAT Gateway 自体に Security Group は設定できない。
- NAT Gateway は通信していなくても時間単位で課金される。
- データ処理量に応じた課金も発生する。
- EC2 を停止しても NAT Gateway の課金は止まらない。
- 本番環境でゾーン単位の NAT Gateway を使用する場合は、可用性や AZ 間通信コストを考慮して AZ ごとに配置することを検討する。

### 6. Route Table

ルートテーブルは宛先 IP アドレスに応じて通信の転送先を決定する。

#### パブリックサブネット用

```hcl
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "public"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
```

#### プライベートサブネット用

```hcl
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "private"
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}
```

Internet Gateway には `gateway_id`、NAT Gateway には `nat_gateway_id` を使用する。

#### ルートを独立したリソースとして管理する

`route` ブロックの代わりに `aws_route` を使用することもできる。

```hcl
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route" "private_default" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}
```

同一ルートテーブルに対して `route` ブロックと `aws_route` を混在させない。

#### local ルート

VPC 内の通信に使用する `local` ルートは AWS が自動的に追加するため、Terraform で明示的に定義する必要はない。

VPC の CIDR が `10.0.0.0/16` の場合、ルートテーブルは以下のようになる。

**Public Route Table**

| Destination | Target |
| --- | --- |
| 10.0.0.0/16 | local |
| 0.0.0.0/0 | Internet Gateway |

**Private Route Table**

| Destination | Target |
| --- | --- |
| 10.0.0.0/16 | local |
| 0.0.0.0/0 | NAT Gateway |

ルーティングでは最長プレフィックス一致（Longest Prefix Match）が使用される。

プライベートサブネットから通信する場合：

- `10.0.1.10` 宛て：local
- `8.8.8.8` 宛て：NAT Gateway

同一 VPC 内の通常の通信は NAT Gateway や Internet Gateway を経由しない。

#### サブネットとの関連付け

- 1つのルートテーブルを複数のサブネットに関連付けられる。
- 1つのサブネットに適用されるルートテーブルは1つだけ。
- 明示的に関連付けない場合、VPC のメインルートテーブルが使用される。

### 7. Security Group

Security Group はリソースに対する通信の許可ルールを定義するステートフルなファイアウォール。

- `ingress`: インバウンド通信
- `egress`: アウトバウンド通信

#### アウトバウンド通信用

```hcl
resource "aws_security_group" "outbound" {
  name   = "outbound"
  vpc_id = aws_vpc.main.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "outbound"
  }
}
```

`protocol = "-1"` はすべてのプロトコルを表す。

#### SSH 用

```hcl
resource "aws_security_group" "ssh" {
  name   = "ssh"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["203.0.113.10/32"]
  }

  tags = {
    Name = "ssh"
  }
}
```

`203.0.113.10` は例示用 IP アドレスなので、実際の接続元 IP アドレスに置き換える。

#### HTTP / HTTPS 用

```hcl
resource "aws_security_group" "web" {
  name   = "web"
  vpc_id = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "web"
  }
}
```

`from_port = 80`、`to_port = 443` とすると、その間のすべてのポートを許可してしまうため注意する。

#### dynamic ブロックによる記述

ポート番号以外の設定が同じ場合は、`dynamic` ブロックでまとめられる。

```hcl
resource "aws_security_group" "web" {
  name   = "web"
  vpc_id = aws_vpc.main.id

  dynamic "ingress" {
    for_each = [80, 443]

    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
}
```

#### Security Group を接続元として指定する

ALB からの通信のみを許可する場合などに使用する。

```hcl
ingress {
  from_port       = 80
  to_port         = 80
  protocol        = "tcp"
  security_groups = [aws_security_group.alb.id]
}
```

IP アドレスではなく、接続元リソースに割り当てられた Security Group に基づいて通信を許可できる。

#### ルールを独立したリソースとして管理する

```hcl
resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.ssh.id

  cidr_ipv4   = "203.0.113.10/32"
  ip_protocol = "tcp"
  from_port   = 22
  to_port     = 22
}
```

```hcl
resource "aws_vpc_security_group_egress_rule" "outbound" {
  security_group_id = aws_security_group.outbound.id

  cidr_ipv4   = "0.0.0.0/0"
  ip_protocol = "-1"
}
```

同一 Security Group に対してインラインの `ingress` / `egress` ブロックと独立したルールリソースを混在させない。

#### EC2 Instance Connect 用

ブラウザ経由の EC2 Instance Connect では、AWS のマネージドプレフィックスリストを利用できる。

```hcl
data "aws_ec2_managed_prefix_list" "ssh" {
  name = "com.amazonaws.ap-northeast-1.ec2-instance-connect"
}
```

```hcl
ingress {
  from_port       = 22
  to_port         = 22
  protocol        = "tcp"
  prefix_list_ids = [data.aws_ec2_managed_prefix_list.ssh.id]
}
```

#### Security Group の特徴

- 1つの EC2 に複数の Security Group を割り当てられる。
- 複数の Security Group の許可ルールは OR 条件で評価される。
- 明示的な拒否ルールは存在しない。
- 許可された通信に対する応答は、逆方向の許可ルールがなくても通過できる（ステートフル）。

### 8. EC2

#### AMI の取得

SSM Parameter Store から Amazon Linux 2023 の最新 AMI を取得する。

```hcl
data "aws_ssm_parameter" "ami" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}
```

AMI ID を直接指定する必要がなく、リージョンごとの AMI ID の違いを吸収できる。

ただし、最新 AMI が更新されると Terraform の実行時に EC2 の再作成が発生する可能性がある。再現性を重視する場合は AMI を固定する。

#### EC2 インスタンスの作成

```hcl
resource "aws_instance" "main" {
  ami                         = data.aws_ssm_parameter.ami.value
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.private.id
  associate_public_ip_address = false

  vpc_security_group_ids = [
    aws_security_group.outbound.id,
    aws_security_group.ssh.id,
    aws_security_group.web.id,
  ]

  tags = {
    Name = "main"
  }
}
```

パブリックサブネットに配置する場合は以下のように変更する。

```hcl
subnet_id                   = aws_subnet.public.id
associate_public_ip_address = true
```

#### user_data

EC2 の初回起動時に実行するスクリプトを指定する。

```hcl
user_data = <<-EOF
  #!/bin/bash
  dnf install -y nginx
  systemctl enable --now nginx
EOF

user_data_replace_on_change = true
```

外部ファイルとして管理することもできる。

```hcl
user_data = file("${path.module}/user_data.sh")
```

`user_data_replace_on_change = true` を指定すると、`user_data` の変更時に EC2 が再作成される。

初回起動時からインターネット接続が必要な場合は、ルートテーブルの関連付けが完了してから EC2 を作成するように依存関係を追加するとよい。

```hcl
depends_on = [
  aws_route_table_association.public,
  aws_route_table_association.private,
]
```

#### プライベートサブネット内の EC2 への接続

プライベートサブネット内の EC2 はパブリック IP を持たないため、Security Group で SSH を許可するだけではインターネットから直接接続できない。

接続方法には以下がある。

- SSM Session Manager
- EC2 Instance Connect Endpoint
- 踏み台サーバー（Bastion Host）

SSM Session Manager を利用する場合は、SSM Agent、適切な IAM ロール、SSM サービスへの通信経路が必要となる。

### 9. 全体構成

```text
Internet
    |
Internet Gateway
    |
VPC (10.0.0.0/16)
    |
    +-- Public Subnet (10.0.1.0/24)
    |     |
    |     +-- NAT Gateway
    |     |     +-- Elastic IP
    |     |
    |     +-- Route Table
    |           +-- 10.0.0.0/16 -> local
    |           +-- 0.0.0.0/0   -> IGW
    |
    +-- Private Subnet (10.0.2.0/24)
          |
          +-- EC2
          |     +-- Security Group (Outbound)
          |     +-- Security Group (SSH)
          |     +-- Security Group (Web)
          |
          +-- Route Table
                +-- 10.0.0.0/16 -> local
                +-- 0.0.0.0/0   -> NAT Gateway
```

### 10. Terraform リソース一覧

| リソース | 役割 |
| --- | --- |
| `aws_vpc` | 仮想ネットワーク |
| `aws_subnet` | VPC 内のネットワーク分割 |
| `aws_internet_gateway` | インターネットへの接続 |
| `aws_eip` | 固定パブリック IPv4 アドレス |
| `aws_nat_gateway` | プライベート IP のアドレス変換 |
| `aws_route_table` | ルーティングテーブル |
| `aws_route` | 個別のルーティングルール |
| `aws_route_table_association` | サブネットとルートテーブルの関連付け |
| `aws_security_group` | 通信の許可ルール |
| `aws_vpc_security_group_ingress_rule` | 個別のインバウンドルール |
| `aws_vpc_security_group_egress_rule` | 個別のアウトバウンドルール |
| `aws_instance` | EC2 インスタンス |
