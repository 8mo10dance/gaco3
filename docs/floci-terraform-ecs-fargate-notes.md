# Floci + Terraform で学ぶ ECS/Fargate と VPC ネットワーク

作成日：2026-11-05  
元の会話：[FlociでFargate利用](chatgpt-conversation://6ae9bd3b-dbb8-83ee-9d97-c58bdf56f24e)

> 参照できた会話の内容を整理した学習ノートです。会話中の ECS/nginx の設定をもとに、Provider・VPC などを補ってコード例を再構成しています。元の作業環境のファイルをそのまま複製したものではありません。コードは本資料の作成時に実行検証していません。Floci 固有の設定は末尾の公式資料で補足確認しました。

## 1. 最初に押さえること

- **ECS はコンテナの管理、Fargate はその実行基盤**。両者は役割が異なる。
- **ルートテーブルは転送先、Security Group は通信の許可を決める**。
- **Public / Private Subnet の違いは経路で決まる**。Security Group の設定とは独立している。
- **Security Group は VPC に属し、Fargate ではタスクの ENI に適用される**。サブネットにアタッチするものではない。
- **NACL はサブネット境界の通信制御**。Security Group と適用対象・状態管理が異なる。
- Floci では AWS API を通じて構成を学べるが、コンテナの実行場所はローカルの Docker。実 AWS の通信経路と同一とは限らない。

## 2. 全体構成

今回の例は、1つの Public Subnet に nginx タスクを1個起動する最小の学習構成です。ALB、NAT Gateway、独自 NACL、IAM ロール、ログ転送は含めません。

```text
管理上の関係
Terraform → Floci の AWS 互換 API
              ├─ ECS Cluster
              ├─ Task Definition（nginx の実行設定）
              └─ ECS Service（タスクを1個維持）
                         └─ Task を起動

実 AWS に置き換えたネットワークの概念図（IPv4）
Internet
   │
Internet Gateway ← Public Subnet の既定経路 0.0.0.0/0
   │
VPC 10.0.0.0/16
   └─ Public Subnet 10.0.1.0/24［境界の NACL］
        └─ Task ENI［Security Group：受信 TCP 80 を許可］
             └─ Fargate Task
                  └─ nginx:alpine（TCP 80）
```

Cluster、Task Definition、Service は論理的な管理リソースです。Service 自体がサブネットの中にあるという意味ではなく、指定されたサブネットにタスクの ENI が配置されます。上図は AWS の内部配線や厳密なパケット処理順を示すものではありません。

### Terraform の準備：Floci を接続先にする

以降は、説明する要素ごとに Terraform の例を示します。基本構成のコードブロックを同じ専用ディレクトリの `main.tf` に追記すると、1つの構成になります。記述順よりもリソースの参照関係で作成順が決まるため、後のセクションで定義するリソースも参照できます。複数 AZ のセクションは拡張例として扱います。

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region     = "ap-northeast-1"
  access_key = "test"
  secret_key = "test"

  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    ec2 = "http://localhost:4566"
    ecs = "http://localhost:4566"
  }
}
```

`endpoints` で EC2/VPC と ECS の API の送信先を Floci にします。ダミー認証情報と `skip_*` は、ローカルで実 AWS の認証確認などを省くための設定です。

Provider を Docker 内から実行する場合、`localhost` はそのコンテナ自身です。Floci のサービス名など、実際に到達できるアドレスに変更します。追加リソースで IAM、CloudWatch Logs などの API を使う場合は、その endpoint も追加します。[Floci の Terraform 設定](https://floci.io/floci/getting-started/terraform/)

## 3. ECS の構成要素

| 要素 | 役割 | 例え |
|---|---|---|
| Cluster | Service や Task をまとめて管理する論理グループ | 管理用のまとまり |
| Task Definition | イメージ、CPU、メモリ、ポートなどの実行設定 | 設計図 |
| Task | 定義から起動された、1つ以上のコンテナをまとめた実行単位 | 設計図から作った実体 |
| Service | 指定数の Task を維持し、更新を管理する | 稼働状態を維持する管理者 |
| Fargate | EC2 ホストを自分で管理せずに Task を実行する AWS の基盤 | 実行場所 |

Cluster を作るだけではコンテナは起動しません。単発のバッチなら `RunTask`、常駐 Web サーバーなら Service を使う、と考えると整理できます。

`desired_count = 1` は「1個動かしたい」という宣言です。実 AWS では停止したタスクを Service が置き換えます。常時監視するのは Terraform ではなく ECS です。Floci での再起動・復旧動作は利用バージョンの実装を確認してください。

### Cluster：管理するまとまりを作る

```hcl
resource "aws_ecs_cluster" "main" {
  name = "floci-cluster"
}
```

この定義で Cluster を作ります。Fargate では自分で EC2 ホストを用意する必要はありません。

### Task Definition：nginx の実行方法を定義する

```hcl
resource "aws_ecs_task_definition" "nginx" {
  family                   = "floci-nginx"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"

  container_definitions = jsonencode([
    {
      name      = "nginx"
      image     = "nginx:alpine"
      essential = true
      portMappings = [
        {
          containerPort = 80
          protocol      = "tcp"
        }
      ]
    }
  ])
}
```

`requires_compatibilities` は Fargate 向けの定義であることを示し、`awsvpc` はタスクごとに ENI を使うネットワークモードです。CPU `256` は 0.25 vCPU、メモリ `512` は 512 MiB を表します。

`jsonencode` は Terraform のオブジェクトを ECS 用の JSON 文字列に変換します。`essential = true` により nginx が停止するとタスク全体も停止します。`containerPort = 80` はアプリ用ポートの定義で、SG の許可や経路を自動作成する設定ではありません。

### Service：タスクを起動し、1個の状態を維持する

```hcl
resource "aws_ecs_service" "nginx" {
  name            = "floci-nginx-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.nginx.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = [aws_subnet.public.id]
    security_groups  = [aws_security_group.ecs.id]
    assign_public_ip = true
  }

  # subnet_id の参照だけでは、ルートの関連付け完了までは保証されない。
  depends_on = [aws_route_table_association.public]
}
```

`subnets` はタスク ENI の配置先、`security_groups` はその ENI に適用する SG です。これらのリソースは次のネットワークのセクションで定義します。`assign_public_ip = true` は、実 AWS ではタスク ENI にパブリック IPv4 を割り当てる指定です。

Terraform は参照から Service → Cluster / Task Definition / Subnet / SG の依存関係を推定します。ただし、サブネットを参照するだけでは、ルートの関連付け完了までは保証されません。この例の `depends_on` は、その準備が終わってから Service を作成するためのものです。

作成後に Cluster と Service の名前を表示するには、次も追加します。

```hcl
output "cluster_name" {
  value = aws_ecs_cluster.main.name
}

output "service_name" {
  value = aws_ecs_service.nginx.name
}
```

## 4. VPC とネットワークの役割

| 要素 | 何を決めるか | 関連付け先・範囲 |
|---|---|---|
| VPC | プライベートな IP ネットワークの範囲 | リージョン内 |
| Subnet | VPC 内の IP 範囲を分割し、配置先を決める | 1つの VPC、1つの AZ |
| Route Table | 宛先に応じた次の転送先 | サブネットに関連付ける |
| Internet Gateway（IGW） | VPC とインターネットを接続する | VPC にアタッチ |
| ENI | タスクなどが通信する仮想 NIC | 1つのサブネット |
| Security Group（SG） | ENI などに対する通信の許可 | SG 自体は VPC に所属 |
| Network ACL（NACL） | サブネット境界を通る通信の許可・拒否 | サブネットに関連付ける |

### VPC と Subnet

例では VPC が `10.0.0.0/16`、Subnet がその一部の `10.0.1.0/24` です。同じ VPC のサブネット間には通常 `local` 経路がありますが、経路があるだけでアプリケーションに接続できるとは限りません。SG、NACL、待受ポートなども条件になります。

1つのサブネットは1つの Availability Zone（AZ）に属します。複数 AZ を使うには、AZ ごとにサブネットを用意します。

```hcl
resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "floci-vpc" }
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-northeast-1a"
  tags = { Name = "floci-public-a" }
}
```

`vpc_id = aws_vpc.main.id` により、サブネットを上で作成した VPC に所属させます。`availability_zone` が配置する AZ です。

### Public と Private

IPv4 の基本例は次のとおりです。

```text
Public Subnet:   0.0.0.0/0 → Internet Gateway
Private Subnet:  0.0.0.0/0 → NAT Gateway（外向き通信が必要な場合）
Isolated Subnet: インターネット向けの既定経路なし
```

Private Subnet に NAT Gateway が必須という意味ではありません。通信先によっては VPC Endpoint を使い、インターネット経由の通信をなくす構成も可能です。

Public Subnet のタスクにインターネットから **IPv4 で直接** 接続するには、IGW への経路、タスクへのパブリック IPv4 割り当て、SG/NACL の許可、アプリの待受が必要です。Public Subnet に置いただけですべてのタスクが公開されるわけではありません。

反対に、Private Subnet の SG で TCP 80 を `0.0.0.0/0` に許可しても、それだけで直接公開されることはありません。公開 ALB を経由して Private Subnet のタスクへ到達させる構成は別途可能です。

### Internet Gateway とルートテーブルを設定する

```hcl
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}
```

IGW を VPC にアタッチし、既定経路 `0.0.0.0/0` の転送先に指定します。さらに Route Table Association で、このルートテーブルを `public` サブネットに関連付けます。ルートテーブルを作っただけでは、そのサブネットで利用されるとは限りません。

## 5. Security Group の Ingress / Egress

Ingress は対象への受信、Egress は対象からの送信です。HTTP クライアントと nginx の例では、最初の接続は nginx の TCP 80 への Ingress です。

SG は **許可ルールのみ** を持ち、明示的な deny は書けません。どの許可にも一致しない新規通信は拒否されます。複数 SG を付けた場合は、各 SG の許可を合わせて評価します。

SG はステートフルです。許可した受信通信への応答は、Egress に同じ通信の許可がなくても通ります。逆に、許可した送信通信の応答も Ingress で個別に許可する必要はありません。以下の全許可 Egress は、HTTP 応答のために必須なのではなく、タスクから新たに開始する外向き通信を広く許可する設定です。

```hcl
resource "aws_security_group" "ecs" {
  name   = "floci-ecs-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```

`vpc_id` で SG が属する VPC を指定します。Service の `security_groups` からこの SG を参照することで、タスクの ENI に適用されます。

`protocol = "-1"` は全プロトコルです。この場合、ポート番号の 0 は「ポート0だけ許可」という意味ではありません。`0.0.0.0/0` は全 IPv4 アドレスを表します。学習例は広い許可ですが、実運用では公開先・通信先に合わせて絞ります。

同じサブネット内でも、Web 用と DB 用で異なる SG を適用できます。例えば DB 側で「Web の SG を持つ ENI から TCP 3306 を許可」とすれば、役割に沿った通信制御ができます。SG の参照はルートを作成せず、参照先 SG のルールを複製するものでもありません。

## 6. SG と NACL の違い

| 観点 | Security Group | Network ACL |
|---|---|---|
| 適用対象 | ENI など | サブネット境界 |
| 状態管理 | ステートフル | ステートレス |
| ルール | 許可のみ | 許可と拒否 |
| 評価方法 | 許可ルールをまとめて評価 | 小さいルール番号から評価し、最初の一致を採用 |
| 戻り通信 | 許可済み通信の応答を自動で許可 | 戻り方向も明示的な許可が必要 |
| 同一サブネット内の ENI 間通信 | 適用される | 通常その通信はサブネット境界を越えないため対象外 |

例えば NACL で外部から Web サーバーの TCP 80 を許可する場合、応答の宛先になるクライアントの一時ポート（エフェメラルポート）への送信も考慮します。必要な範囲はクライアントや通信経路に依存します。

AWS のデフォルト NACL は初期状態で全通信を許可します。新しく作ったカスタム NACL は、ルールを追加するまで全通信を拒否します。今回の Terraform 例は独自 NACL を作らず、VPC のデフォルト NACL を使います。

会話での「サブネットで通信を制御する」というイメージは NACL に対応します。一方、SG はサーバー側の ENI に適用する仕組みです。[AWS の SG/NACL 比較](https://docs.aws.amazon.com/vpc/latest/userguide/infrastructure-security.html)

## 7. 物理ネットワークとの対応

| AWS | 物理ネットワークで近いもの | 例えの限界 |
|---|---|---|
| VPC | 会社全体のプライベートネットワーク | AWS が提供する論理ネットワーク |
| Subnet | IP サブネット、VLAN で分けた区画 | VLAN と完全に同じではなく、通常の L2 機能をそのまま期待できない |
| Route Table | ルーターの経路設定 | 独立した物理ルーターを自分で設置するわけではない |
| IGW | インターネットへの接続ルーター | AWS 管理の論理的なゲートウェイ |
| ENI | NIC、ネットワークカード | 仮想インターフェース |
| SG | 各サーバーのファイアウォール | OS 内の設定ではなく、ENI に適用される分散的な制御 |
| NACL | 区画の境界にあるルーターや機器の ACL | ステートレスで、同一サブネット内を一律に制御するものではない |
| Fargate Task | NIC を持つアプリケーションサーバー | 物理マシンそのものではなく、コンテナ群の実行単位 |

```text
社内ネットワーク（VPC）
  └─ 区画（Subnet）
       ├─ Web サーバーの NIC（ENI）＋ Web 用 FW（SG）
       └─ DB サーバーの NIC（ENI）＋ DB 用 FW（SG）

区画の出入口：NACL
経路案内：Route Table
外部との接続口：Internet Gateway
```

ルーターに外への経路があっても、ファイアウォールが TCP 80 を通さなければ HTTP 接続はできません。ファイアウォールが許可しても、到達する経路がなければ接続できません。この「経路」と「許可」の分離が最も重要です。

Public Subnet はそのまま物理ネットワークの DMZ と同義ではありません。Public は IGW への経路の性質を表し、公開するアプリや境界防御の設計までは決めません。

### Terraform の設定属性とその意味

各セクションで示したコードの主な属性を一覧にすると、次のとおりです。

| 設定 | 理由 |
|---|---|
| Provider の `endpoints` | Terraform の EC2/VPC と ECS API の送信先を Floci にする |
| ダミー認証情報と `skip_*` | ローカル用に実 AWS の認証確認などを省く |
| IGW ＋ `0.0.0.0/0` のルート | 実 AWS 上で Public Subnet となる経路を表現する |
| Route Table Association | 作成したルートを対象サブネットで使う |
| `awsvpc` | Fargate で必要なネットワークモード。タスクごとに ENI を使う |
| CPU 256 / Memory 512 | 0.25 vCPU / 512 MiB の構成 |
| `jsonencode` | Terraform のオブジェクトを ECS が受け取る JSON 文字列にする |
| `essential = true` | nginx が停止するとタスク全体も停止する |
| `containerPort = 80` | コンテナのサービス用ポートを定義する。SG の許可や経路を自動作成するわけではない |
| `assign_public_ip = true` | 実 AWS ではタスク ENI にパブリック IPv4 を割り当てる |

## 8. Floci の起動と確認

以下の Compose は本資料で補ったローカル学習例です。Floci の現行ドキュメントにあるホスト公開設定を使い、タスクの TCP 80 を動的なホストポートに公開します。古いバージョンでは設定や応答形式が異なる場合があります。

### compose.yaml

```yaml
services:
  floci:
    image: floci/floci:latest
    ports:
      - "127.0.0.1:4566:4566"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    environment:
      FLOCI_SERVICES_ECS_MOCK: "false"
      FLOCI_SERVICES_ECS_DOCKER_NETWORK: floci-learning
      FLOCI_SERVICES_ECS_PUBLISH_AWSVPC_PORTS_TO_HOST: "true"
      FLOCI_SERVICES_ECS_DYNAMIC_AWSVPC_HOST_PORTS: "true"
      FLOCI_SERVICES_ECS_HOST_PORT_BIND_ADDRESS: "127.0.0.1"
    networks:
      - learning

networks:
  learning:
    name: floci-learning
```

再現性が必要な場合は、動作確認した Floci イメージのタグまたは digest に固定してください。`latest` と `nginx:alpine` は将来変化します。Provider は初期化で生成される `.terraform.lock.hcl` も保存します。

Docker ソケットを渡すため、Floci はホストの Docker 上にコンテナを作成できます。この例では Floci のデータ保存用ボリュームを設定していないため、コンテナ再作成後の永続性は前提にしません。

### 実行手順

Docker、Terraform、AWS CLI を利用できるローカル環境で実行します。

```bash
docker compose up -d
terraform init
terraform fmt
terraform validate
terraform plan
terraform apply
```

Floci の API 用ポート `4566` は nginx の HTTP ポートではありません。タスク起動後、以下で実際のホスト公開ポートを確認します。

```bash
export AWS_ACCESS_KEY_ID=test
export AWS_SECRET_ACCESS_KEY=test
export AWS_DEFAULT_REGION=ap-northeast-1

aws --endpoint-url=http://localhost:4566 ecs describe-services \
  --cluster floci-cluster \
  --services floci-nginx-service

aws --endpoint-url=http://localhost:4566 ecs list-tasks \
  --cluster floci-cluster

# 上の結果に含まれる ARN を設定する。
TASK_ARN='ここを取得したタスクARNに置き換える'

aws --endpoint-url=http://localhost:4566 ecs describe-tasks \
  --cluster floci-cluster \
  --tasks "$TASK_ARN" \
  --query 'tasks[].containers[].networkBindings[]'

# 表示された hostPort に置き換える。
curl http://127.0.0.1:<hostPort>/
```

動的ポートにすることで、更新中に旧タスクと新タスクが一時的に並存しても同じホストポートの競合を避けられます。Docker が別のマシンで動いている場合、ここでいうホストは Docker デーモンのホストです。[Floci のタスクポート公開設定](https://floci.io/floci/services/ecs/#host-access-to-awsvpc-task-ports)

### 終了

同じ学習ディレクトリで、対象の plan を確認してから削除します。

```bash
terraform plan -destroy
terraform destroy
docker compose down
```

先に Floci を停止すると Terraform から削除 API にアクセスできなくなるため、リソース削除を先に行います。

## 9. 複数サブネット・複数 AZ に広げる

SG はサブネット所属ではないので、同じ VPC 内の複数サブネットにあるタスクへ同じ SG を適用できます。

例えば既存の `main.tf` に次のリソースを追加します。

```hcl
resource "aws_subnet" "public_b" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-northeast-1c"
}

resource "aws_route_table_association" "public_b" {
  subnet_id      = aws_subnet.public_b.id
  route_table_id = aws_route_table.public.id
}
```

既存 Service の `desired_count` を `2` にし、次の設定へ置き換えます。Service リソース自体を重複して追加する必要はありません。

```hcl
network_configuration {
  subnets = [
    aws_subnet.public.id,
    aws_subnet.public_b.id,
  ]
  security_groups  = [aws_security_group.ecs.id]
  assign_public_ip = true
}

depends_on = [
  aws_route_table_association.public,
  aws_route_table_association.public_b,
]
```

Service は指定サブネット群から配置先を選びます。1つのタスク ENI が複数サブネットにまたがるのではありません。指定したすべてのサブネットと SG は同じ VPC に属する必要があります。

実 AWS の ECS は AZ 間の分散を考慮しますが、「必ず各サブネットに1個ずつ」という保証とは分けて考えます。複数 AZ にサブネットを作り、必要数のタスクと負荷分散を組み合わせて可用性を設計します。Floci 上で AZ 名を分けても、物理的な障害分離にはなりません。

Cluster 自体は特定の VPC に固定されません。同じ Cluster 内で、別々の Service / Task を異なる VPC に配置することは可能ですが、1つの Service のネットワーク設定で異なる VPC のサブネットを混在させることはできません。

## 10. Floci と実 AWS の違い・注意点

### ローカルの Fargate は Docker によるエミュレーション

`launch_type = "FARGATE"` を指定しても、ローカルに AWS の Fargate 基盤が用意されるわけではありません。API 上の構成と、実際の Docker の通信経路を分けて理解します。SG/NACL/ルートを API で作成できることだけで、すべての通信制御が実 AWS と同じように強制されるとは判断できません。

利用する Floci バージョンと設定で、期待する通信が通ること・拒否されることの両方を確認します。タスクに報告されるアドレス、Docker ネットワーク内のアドレス、ホストに公開されたアドレスも区別します。

### Mock モードの RUNNING はアプリ起動を意味しない

`FLOCI_SERVICES_ECS_MOCK=true` では Docker コンテナを起動せず、API 上のタスク状態を模擬します。nginx にアクセスしたい場合は実コンテナを使う設定と Docker ソケットが必要です。[Floci ECS の説明](https://floci.io/floci/services/ecs/)

### 実 AWS に移す前に補うもの

このコードの Provider 設定を切り替えるだけで本番構成が完成するわけではありません。

- 実 AWS 用の認証、必要な IAM 権限、必要に応じた Task Execution Role / Task Role を設計する。Execution Role はイメージ取得やログ転送など、Task Role はアプリ自身の AWS API 呼び出しに使う。
- イメージ取得・ログ送信などの外向き経路を確保する。Private Subnet では NAT や必要な VPC Endpoint などを検討する。
- 継続して公開する Web サービスは、通常 ALB、HTTPS、ヘルスチェック、ログ、複数 AZ を組み合わせる。直接のタスク IP はタスク更新で変わり得る。
- nginx の公開許可、Egress、イメージの固定、CPU・メモリ、タスク数を用途に合わせる。
- 実 AWS での料金・利用可能な AZ・API の制約を確認する。

## 11. 接続できないときの確認順

1. **実体**：Service のイベント、タスクの状態、停止理由を確認する。Mock モードではないか。
2. **アプリ**：イメージ取得に成功したか、nginx が起動し TCP 80 を待ち受けているか。
3. **接続先**：Floci の API ポートと nginx の公開ポートを取り違えていないか。
4. **ローカル実行環境**：Docker ソケット、ネットワーク名、公開ポート、ポート競合を確認する。
5. **AWS の経路設計**：サブネットとルートテーブルの関連付け、IGW、パブリック IP、必要なら NAT/Endpoint を確認する。
6. **通信許可**：SG の新規通信許可、NACL の往復許可、実際に適用される SG/NACL を確認する。

「Public だから通る」「SG を許可したから通る」という単独の条件で判断せず、実体・経路・許可を順に確認します。

## 12. 参照資料

元の会話を整理したうえで、Floci 固有の補足は以下の公式資料で確認しました。リンク先は更新されるため、再現時には使用バージョンのドキュメントも確認してください。

- [Floci：Terraform](https://floci.io/floci/getting-started/terraform/)
- [Floci：ECS（Docker 実行・Mock・ホストポート公開）](https://floci.io/floci/services/ecs/)
- [Floci：Docker Configuration](https://floci.io/floci/configuration/docker/)
- [AWS：VPC の Security Group と NACL](https://docs.aws.amazon.com/vpc/latest/userguide/infrastructure-security.html)
- [AWS：Fargate タスクの接続問題の確認](https://www.repost.aws/knowledge-center/fargate-connection-issues)
