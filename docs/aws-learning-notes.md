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

### EC2 から Secrets Manager の認証情報を取得

EC2 に付与した IAM ロールに、利用するシークレットを読むための `secretsmanager:GetSecretValue` 権限を付与する。

シークレット名（または ARN）を環境変数 `DB_SECRET_ID` に指定し、AWS CLI で JSON を取得して `jq` で `username` と `password` を取り出す。

```bash
DB_SECRET_ID='任意のシークレット名またはARN'

SECRET=$(aws secretsmanager get-secret-value \
  --secret-id "$DB_SECRET_ID" \
  --region ap-northeast-1 \
  --query SecretString \
  --output text)

DB_USER=$(printf '%s' "$SECRET" | jq -r '.username')
DB_PASSWORD=$(printf '%s' "$SECRET" | jq -r '.password')
```

パスワードは画面やログに出力しない。

### MySQL への接続例

RDS エンドポイントを設定してから接続する。

```bash
DB_HOST='example.abcdefghijkl.ap-northeast-1.rds.amazonaws.com'

mysql \
  -h "$DB_HOST" \
  -P 3306 \
  -u "$DB_USER" \
  -p"$DB_PASSWORD"
```

`mysql` コマンドがない場合は、EC2 の OS に合わせて MySQL または MariaDB クライアントをインストールする。

> 注意: シークレット、シェル変数、接続コマンドに含まれるパスワードを共有・記録しない。
