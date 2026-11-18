# TerraformでEC2にnginxを導入する（Amazon Linux 2023）

参照会話「TerraformでNginx導入」をもとに、実行に必要な前提とコードを整理した技術メモです。確認日：2026年11月18日。

## 1. 構成と前提

既存のVPC・パブリックサブネットにEC2を1台作成し、初回起動時に`user_data.sh`でnginxを導入します。SSH用とHTTP用のセキュリティグループ（SG）を同じEC2に関連付けます。

| 項目 | 前提 |
| --- | --- |
| OS・CPU | Amazon Linux 2023、x86_64。例では`t3.micro`を使用 |
| リージョン | 例では東京（`ap-northeast-1`） |
| VPC・サブネット | 同じリージョンの既存リソース。指定サブネットは指定VPCに所属すること |
| インターネット経路 | VPCにInternet Gateway（IGW）が接続され、サブネットのルートテーブルに`0.0.0.0/0 → IGW`があること |
| パブリックIPv4 | EC2作成時に明示的に割り当てる。IPを付けるだけでは経路は作られない |
| DNS・外向き通信 | VPCのDNS解決が有効で、パッケージリポジトリに到達できること |
| SSH | 同じリージョンに登録済みのEC2キーペアと対応する秘密鍵があること |
| 認証・権限 | Terraformの実行環境にAWS認証情報と必要なEC2・SG・SSMパラメータ参照権限があること |
| ネットワークACL | SSH・HTTP・外向き通信とその応答を許可していること。ACLはステートレス |

VPC・サブネット・IGW・ルート・キーペア自体は、以下のコードでは作成しません。デフォルトVPCの存在にも依存しません。プライベートサブネットで実行する場合は、パッケージ取得用のNATなどと、SSHやWebアクセス用の別経路が必要です。

これはIPv4のHTTP動作確認用です。HTTPSやIPv6の公開設定は含みません。EC2、EBS、パブリックIPv4などには料金が発生します。

## 2. ファイル構成

```text
terraform-nginx/
├── main.tf
├── terraform.tfvars
└── user_data.sh
```

## 3. user_data.sh：nginxの導入

ファイルはUTF-8・LF改行で保存し、先頭に空行やBOMを入れず、1行目をshebangにします。

```bash
#!/bin/bash
set -euo pipefail

dnf install -y nginx

cat > /usr/share/nginx/html/index.html <<'HTML'
<!doctype html>
<html lang="ja">
<head><meta charset="utf-8"><title>Terraform nginx</title></head>
<body><h1>Hello from Terraform!</h1></body>
</html>
HTML

nginx -t
systemctl enable --now nginx
```

`enable`はOS再起動時の自動起動を有効にし、`--now`はその場で起動します。user dataはrootとして動くため、スクリプト内の`sudo`は不要です。`set -euo pipefail`でコマンド失敗や未定義変数を検出します。途中で失敗すると後続処理は実行されません。

必要に応じてインストール前に`dnf upgrade -y`を追加できますが、更新時間や更新範囲が増え、カーネル更新などは再起動が必要な場合があります。検証済みAMIと更新方針に合わせて選びます。

### ローカルファイルに+xは不要

```hcl
user_data = file("${path.module}/user_data.sh")
```

Terraformの`file()`はファイルの内容を文字列として読む関数です。ローカルで実行しないため、`chmod +x user_data.sh`は不要で、Terraformの実行ユーザーに読み取り権限があれば十分です。ローカルの実行権限はAWSに転送されません。

一方、今回のようにプレーンなシェルスクリプトをuser dataとして渡す場合、先頭の`#!/bin/bash`はcloud-initによるスクリプトの識別と実行に必要です。cloud-config形式なら`#cloud-config`など、別形式の識別子を使用します。

| ローカルでの使い方 | +x |
| --- | --- |
| Terraformの`file()`で読み込む | 不要 |
| `bash user_data.sh`で実行する | 不要 |
| `./user_data.sh`で直接実行する | 必要 |

根拠：[AWS：Linux user dataとシェルスクリプト](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html)。

## 4. main.tf：EC2とSGの定義

AWS Provider 6系を使用する例です。`terraform init`で生成される`.terraform.lock.hcl`は保存・共有し、実際のProviderバージョンを固定してください。

```hcl
terraform {
  required_version = ">= 1.5.0, < 2.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

variable "vpc_id" {
  type        = string
  description = "Existing VPC ID"
}

variable "subnet_id" {
  type        = string
  description = "Existing public subnet ID in the VPC"
}

variable "key_name" {
  type        = string
  description = "Existing EC2 key pair name"
}

variable "ssh_cidr" {
  type        = string
  description = "Administrator public IPv4 address with /32"

  validation {
    condition = (
      can(cidrnetmask(var.ssh_cidr)) &&
      can(regex("/32$", var.ssh_cidr))
    )
    error_message = "Specify a valid IPv4 /32 CIDR for SSH."
  }
}

# リージョンごとのAL2023標準x86_64 AMIを取得
# 最新AMIへの更新が、次回planでEC2置換を発生させる場合がある
data "aws_ssm_parameter" "al2023" {
  name = "/aws/service/ami-amazon-linux-latest/al2023-ami-kernel-default-x86_64"
}

resource "aws_security_group" "ssh" {
  name_prefix = "nginx-ssh-"
  description = "SSH from administrator"
  vpc_id      = var.vpc_id

  ingress {
    description = "SSH from administrator IPv4"
    cidr_blocks = [var.ssh_cidr]
    protocol    = "tcp"
    from_port   = 22
    to_port     = 22
  }

  # このSG単体では新規の送信通信を許可しない
  egress = []
}

resource "aws_security_group" "http" {
  name_prefix = "nginx-http-"
  description = "Public HTTP and outbound access"
  vpc_id      = var.vpc_id

  ingress {
    description = "Public HTTP IPv4"
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
    from_port   = 80
    to_port     = 80
  }

  # パッケージ取得など、EC2から開始するIPv4通信を許可
  egress {
    description = "Allow outbound IPv4"
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
  }
}

resource "aws_instance" "web" {
  ami                         = data.aws_ssm_parameter.al2023.value
  instance_type               = "t3.micro"
  subnet_id                   = var.subnet_id
  associate_public_ip_address = true
  key_name                    = var.key_name

  vpc_security_group_ids = [
    aws_security_group.ssh.id,
    aws_security_group.http.id,
  ]

  user_data                   = file("${path.module}/user_data.sh")
  user_data_replace_on_change = true

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name = "terraform-nginx"
  }
}

output "public_ip" {
  value = aws_instance.web.public_ip
}

output "web_url" {
  value = "http://${aws_instance.web.public_ip}"
}
```

`ami`をSSMから取得するため、AMI IDのリージョン差を吸収できます。再現性を重視する場合は、検証したリージョン内のAL2023 AMI IDを変数などで固定してください。`t4g`系を使う場合はAMIも`arm64`に変更する必要があります。

読みやすさを優先し、各SGの`ingress`・`egress`を`aws_security_group`内にまとめています。SSH用SGの`egress = []`は送信ルールなしを明示し、EC2からの新規送信はHTTP用SGで許可します。EC2はSGのIDを参照しているため、SGとそのルールの作成後に起動され、追加の`depends_on`は不要です。

同じSGに対して、この書き方と別リソース（`aws_vpc_security_group_ingress_rule`・`aws_vpc_security_group_egress_rule`など）によるルール管理を混在させないでください。競合や上書きの原因になります。[HashiCorp：SGの管理方式とデフォルト送信ルール](https://github.com/hashicorp/terraform-provider-aws/blob/main/website/docs/r/security_group.html.markdown)

## 5. terraform.tfvars：環境に合わせる値

```hcl
vpc_id    = "vpc-0123456789abcdef0"
subnet_id = "subnet-0123456789abcdef0"
key_name  = "my-existing-key"
ssh_cidr  = "203.0.113.10/32"
```

上記IDは例示です。`203.0.113.10`も文書用アドレスなので、接続元の実際のグローバルIPv4に置き換えてください。自宅ルーターやVPNの外向きIPが変わった場合は更新が必要です。秘密鍵やAWSアクセスキーは記述しません。

## 6. 実行・確認

各ファイルを同じディレクトリに保存して実行します。

```bash
terraform init
terraform fmt
terraform validate
terraform plan -out=tfplan
terraform apply tfplan
terraform output -raw web_url
```

`apply`完了はcloud-init完了を意味しません。数分待って、出力されたURLにブラウザでアクセスします。`Hello from Terraform!`が表示されればHTTP確認は成功です。

SSH接続例（秘密鍵のパスを置き換える）：

```bash
chmod 600 ~/.ssh/my-existing-key.pem
ssh -i ~/.ssh/my-existing-key.pem ec2-user@<パブリックIPv4>
```

ここでの`chmod 600`はSSH秘密鍵の保護であり、`user_data.sh`に実行権限を付ける操作ではありません。

## 7. cloud-initの仕組みとログ

処理の流れは次のとおりです。

1. Terraformが`file()`でスクリプト本文を読む。
2. AWS ProviderがEC2のuser dataに本文を渡す。`user_data`には平文を指定し、手動のBase64化は不要。
3. Amazon Linux 2023内のcloud-initがインスタンスメタデータ経由でuser dataを取得する。
4. cloud-initが起動処理の一部として、シェルスクリプトをrootで実行する。
5. スクリプトがnginxのインストールと起動を行う。

標準構成では、user dataのスクリプトはインスタンスの初回起動時に実行されます。OS再起動のたびに再実行されるものではありません。nginxの再起動後の起動は`systemctl enable`で設定しています。

EC2にSSH接続した後、以下を確認します。

```bash
# 完了まで待機。cloud-initのエラーも確認する
sudo cloud-init status --wait
sudo cloud-init status --long

# スクリプトの標準出力・標準エラー
sudo tail -n 200 /var/log/cloud-init-output.log

# cloud-init自体の詳細な処理ログ
sudo tail -n 200 /var/log/cloud-init.log

# 最終段階のサービスログ
sudo journalctl -u cloud-final.service -b --no-pager

# nginxの設定・稼働・ローカルHTTP疎通
sudo nginx -t
sudo systemctl status nginx --no-pager
curl -I http://127.0.0.1/
sudo ss -ltnp
```

`cloud-init status`が完了でも、HTTP経路の疎通まで保証されるわけではありません。ログと`curl`を併せて確認します。user dataやログにパスワード、秘密鍵、長期アクセスキーなどを埋め込まないでください。Terraformのstateや保存したplanも適切に保護します。

根拠：[AWS：user dataの実行条件・root実行・ログ](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html)。

## 8. user_data_replace_on_changeの意味

| 設定 | user data本文を変更してapplyしたとき |
| --- | --- |
| `false`（デフォルト） | Providerは通常、既存EC2を停止・更新・起動する。標準cloud-initでは初回実行済みスクリプトは再実行されない |
| `true` | EC2を置換し、新しいインスタンスの初回起動で変更後のスクリプトを実行する |

`true`は「既存OS上でスクリプトを再実行する」設定ではありません。例ではルートEBSを終了時に削除するため、置換するとその中のデータも失われます。停止時間やインスタンスID・パブリックIPv4の変更も発生し得ます。必ず`plan`の置換内容を確認してください。

`file()`は本文だけを読むため、ローカルのファイル権限だけを変えてもuser data本文は変わりません。初期化が途中で失敗しても、同じ本文で再度`apply`するだけでは通常再実行されません。原因修正後に本文変更による置換、または明示的な置換を検討します。

```bash
# 実施前に、EC2とルートディスクが置換される計画を確認する
terraform plan -replace=aws_instance.web -out=replace.tfplan
terraform apply replace.tfplan
```

本番でデータを保持する用途では、永続データの分離やバックアップ、AMI作成・構成管理、冗長化なども設計します。[HashiCorp：aws_instanceのuser_data設定](https://github.com/hashicorp/terraform-provider-aws/blob/main/website/docs/r/instance.html.markdown)

## 9. SSH用・HTTP用SGの分離と評価

EC2には複数SGを関連付けられます。例ではプライマリネットワークインターフェイスにSSH用とHTTP用を関連付けています。

| SG | インバウンド | アウトバウンド |
| --- | --- | --- |
| SSH用 | 管理者IPv4 `/32`からTCP 22 | 独自の許可ルールなし |
| HTTP用 | IPv4全体からTCP 80 | IPv4全通信を許可 |

**関連付けたSGの許可ルールは和集合（OR）になります。受信・送信それぞれで評価されます。** 一方のSGにルールがなくても、他方に許可があればSGの評価では許可されます。SGには明示的な拒否ルールはありません。

例えば別のSGでTCP 22を`0.0.0.0/0`に許可すると、SSH用SGで管理者IPに限定していても、SSHは全IPv4から許可されます。制限の狭いSGを追加しても、別SGの広い許可を打ち消すことはできません。

SGで許可されても、ルート、ACL、OS側のファイアウォール、nginxの待ち受け状態などによって通信は失敗し得ます。[AWS：SGルールの和集合と許可方式](https://docs.aws.amazon.com/vpc/latest/userguide/security-group-rules.html)

### アウトバウンドの注意点

AWSがSGを作成すると通常は全送信許可が付きますが、Terraformの`aws_security_group`で新規作成するとProviderがこのデフォルトを削除します。必要な送信ルールをコードで明示してください。過去の会話のSSH・HTTP分離例に受信ルールしかない場合、それだけではパッケージ取得用の送信許可が不足します。[HashiCorp：デフォルト送信ルールの扱い](https://github.com/hashicorp/terraform-provider-aws/blob/main/website/docs/r/security_group.html.markdown)

この例ではHTTP用SGに全IPv4送信を1つだけ定義しています。SGの和集合によってEC2全体の送信を許可するため、同じルールをSSH用にも重複させる必要はありません。用途に応じて送信専用SGを分けることもできます。

SGはステートフルなので、許可されたSSH・HTTP接続への応答は、対応する送信許可がなくても通過します。ただし、`dnf`などがEC2から新しく開始する通信には送信許可が必要です。[AWS：SGと応答通信](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-security-groups.html)

送信を厳密に絞る場合は、リポジトリへのHTTP/HTTPS、利用するDNS、その他必要な宛先を確認します。VPCのAmazonProvidedDNS（Route 53 Resolver）へのDNS通信はSGでは遮断できないという例外があります。独自DNSには必要なDNS経路と許可を用意します。[AWS：DNSの例外](https://docs.aws.amazon.com/vpc/latest/userguide/security-group-rules.html)

## 10. うまく動かないとき

| 症状 | 主な確認先 |
| --- | --- |
| SSHがタイムアウト | 接続元IPと`ssh_cidr`、パブリックIP、IGWへのルート、ACL、実際に付いているSG |
| SSHの認証エラー | `ec2-user`、キーペアと秘密鍵の対応、秘密鍵の権限 |
| `dnf`で失敗 | cloud-initログ、外向きルート・SG、DNS、リポジトリの到達性 |
| ローカルcurlも失敗 | スクリプトの失敗、nginxの設定・起動・待ち受け |
| ローカルcurlは成功、外部は失敗 | TCP 80のSG、公開IP、ルート、ACL、OSのファイアウォール |
| スクリプトを変更したのに反映されない | `plan`の差分、`user_data_replace_on_change`、変更先ファイル |
| apply直後だけ接続できない | cloud-initがまだ実行中か確認する |

不要になったら`terraform plan -destroy`で対象を確認し、`terraform destroy`でこの構成が作成したリソースを削除します。既存VPC・サブネット・キーペアはこのコードの管理外です。

## 11. 公式資料

- [AWS：EC2 user data](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/user-data.html)
- [AWS：EC2セキュリティグループ](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/ec2-security-groups.html)
- [AWS：VPCのSGルール](https://docs.aws.amazon.com/vpc/latest/userguide/security-group-rules.html)
- [HashiCorp：aws_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance)
- [HashiCorp：aws_security_group](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group)

この資料のコードは公式仕様をもとに作成したサンプルです。実AWS環境へのapplyによる動作検証は行っていません。
