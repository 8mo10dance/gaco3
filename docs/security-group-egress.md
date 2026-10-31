# Floci・AWS 環境の Security Group egress 設定ガイド

Terraform で EC2 環境を構築する際に、ローカルの Floci と本番 AWS で同じ送信制御を適用するための手順です。
このノートのコマンドとパスは、元の検証環境のリポジトリを基準にしています。
構築用の `modules/`、`local/`、`devbox` の設定などは、この学習ドキュメントのリポジトリには含まれていません。
コマンドは、該当する設定を持つ検証環境のリポジトリルートから実行してください。

## 1. 送信ポリシーを決める

`modules/main.tf` の `aws_security_group.ssh` に、必要な egress を明示します。
このモジュールはローカルと本番で共有しています。

| 構築する環境 | egress の設定 |
| --- | --- |
| 起動時に HTTPS リポジトリから nginx などをインストールする | TCP 443 を許可 |
| 新規の外向き通信を遮断する、またはインストール失敗を検証する | `egress = []` |
| その他の外部サービスを利用する | 必要な宛先・プロトコル・ポートを追加 |

HTTPS を使う環境では、SG リソース内に次を設定します。

```hcl
egress {
  protocol    = "tcp"
  from_port   = 443
  to_port     = 443
  cidr_blocks = ["0.0.0.0/0"]
}
```

一般の外向き通信を遮断する環境では、上のブロックの代わりに次を設定します。

```hcl
egress = []
```

`egress` の省略を送信ポリシーとして使わないでください。新規作成時には Provider が既定ルールを削除しますが、既存 SG の更新時に省略しても全削除の指示にはなりません。
TCP 443 の例は IPv4 HTTPS 用です。別ポートや IPv6 を利用する場合は、必要なルールを個別に設定してください。

## 2. Floci の互換性対応を確認する

Floci 2.3.0 と AWS Provider 6.70.0 の組み合わせでは、Terraform が SG の既定の全送信許可を削除できない不具合があります。
enforcement を有効にしても、`egress = []` や443のみの設定に対して全送信許可が残るため、**SG 作成後にローカル専用の削除処理が必要です**。

| 項目 | AWS | 対象バージョンの Floci |
| --- | --- | --- |
| Terraform による既定 egress の削除 | Provider が処理 | 別途 API で削除 |
| `egress = []` の確認 | API が空であることを確認 | state が空でも API に全送信許可が残り得る |
| 443のみの設定 | TCP 443 のみ許可 | 既定ルールを削除しないと全送信許可も残る |

この手順の互換性確認対象は Terraform 1.16.5 / AWS Provider 6.70.0 / Floci 2.3.0 です。
Floci や Provider のバージョンを変える場合は、空 egress と443のみの両方で API・実通信を確認してください。別バージョンでの修正状況はこの手順の保証範囲外です。
Docker イメージと Provider のバージョンを記録・固定すると、環境間で比較しやすくなります。

## 3. ローカル環境を構築する

前提として Docker、Devbox、AWS CLI を利用でき、`keys/floci_key.pub` が存在することを確認してください。
`local/provider.tf` の EC2 endpoint は `http://localhost:4566`、リージョンは `ap-northeast-1` を使用します。

### 3.1 enforcement を有効にして Floci を起動する

`docker-compose.yml` の Floci サービスに次を設定します。

```yaml
environment:
  FLOCI_NETWORK_SECURITY_GROUP_ENFORCEMENT_ENABLED: "true"
```

```bash
docker compose up -d --wait
devbox run tf init -lockfile=readonly
```

### 3.2 EC2 の起動前に SG を作成する

user_data が既定の全送信許可を使ってしまわないように、SG の設定を先に確定します。
対象バージョンの回避処理を挟むため、初回構築では SG とその依存リソースを先行作成します。

```bash
devbox run tf plan -target=module.infrastructure.aws_security_group.ssh
devbox run tf apply -target=module.infrastructure.aws_security_group.ssh
devbox run tf state show module.infrastructure.aws_security_group.ssh
```

`-target` はこの段階構築に限定して使用します。SG の確認後、3.4節で必ず全体を適用します。

### 3.3 既定の全送信許可を削除する

直前の `state show` に表示された `id` を設定してください。SG の再作成後は取り直します。

```bash
SG_ID='sg-xxxxxxxxxxxxxxxxx'  # 実際の SG ID に置き換える

floci_ec2() {
  AWS_ACCESS_KEY_ID=test \
  AWS_SECRET_ACCESS_KEY=test \
  AWS_SESSION_TOKEN= \
  AWS_PAGER= \
  aws --endpoint-url=http://localhost:4566 \
      --region ap-northeast-1 ec2 "$@"
}

floci_ec2 describe-security-groups --group-ids "$SG_ID"
```

`GroupName` と `VpcId` が対象環境のものか確認します。
`IpPermissionsEgress` に、`IpProtocol=-1`、CIDR `0.0.0.0/0`、ポート未設定の既定ルールがあれば削除します。

```bash
floci_ec2 revoke-security-group-egress \
  --group-id "$SG_ID" \
  --ip-permissions \
  '[{"IpProtocol":"-1","IpRanges":[{"CidrIp":"0.0.0.0/0"}]}]'

floci_ec2 describe-security-groups \
  --group-ids "$SG_ID" \
  --query 'SecurityGroups[0].IpPermissionsEgress'
```

**削除要求の `FromPort` と `ToPort` は省略してください。** 0を指定すると、Floci が保持するポート未設定のルールに一致せず削除されません。
既定ルールがすでに存在しない場合は、削除操作を省略して次の確認へ進みます。
この削除は既定の IPv4 全送信許可だけが対象で、TCP 443 などの個別ルールは残します。

| 設定方針 | EC2 起動前に確認する API の状態 |
| --- | --- |
| egress 空 | `IpPermissionsEgress` が `[]` |
| HTTPS のみ | `tcp`、443–443、`0.0.0.0/0` のみ。`IpProtocol=-1` がない |

API が期待する状態になるまで、EC2 の作成に進まないでください。
ポート付きの全送信許可や IPv6 ルールなど、別のルールが残っている場合は、その内容に合わせて設定を見直します。

### 3.4 全体を適用する

```bash
devbox run tf plan
devbox run tf apply
devbox run tf state show module.infrastructure.aws_instance.main
devbox run tf plan
```

最初の全体 plan で SG が再作成される場合は、SG 作成と既定ルール削除の手順をやり直してください。
適用後は API の egress を再確認し、最後の plan に意図しない差分がないことを確認します。

## 4. 通信と初期化結果を確認する

`state show` で取得した EC2 の ID を設定します。

```bash
INSTANCE_ID='i-xxxxxxxxxxxxxxxxx'  # 実際の EC2 ID に置き換える

docker exec "floci-aws-sg-$INSTANCE_ID" \
  nft list chain inet floci_sg egress

docker exec "floci-aws-ec2-$INSTANCE_ID" \
  getent ahostsv4 example.com

docker exec "floci-aws-ec2-$INSTANCE_ID" \
  curl -4 -Iv --noproxy '*' \
  --connect-timeout 5 --max-time 10 https://example.com

docker exec "floci-aws-ec2-$INSTANCE_ID" rpm -q nginx
docker compose logs --tail=200 floci
```

| 確認対象 | egress 空 | HTTPS のみ許可 |
| --- | --- | --- |
| API | 空 | TCP 443 のみ |
| nftables | `policy drop`、一般外向き許可なし | TCP 443 許可あり、全送信許可なし |
| 新規 HTTPS | 名前解決後に接続タイムアウト | 接続成功 |
| 未インストール状態からの nginx 取得 | HTTPS 取得失敗 | 必要な経路・DNS・リポジトリが利用可能なら成功 |

apply 成功や state の値だけで構築完了と判断せず、API・実通信・必要な user_data の完了を確認してください。
SG 制御と dnf の許可／遮断は確認済みですが、段階構築から user_data 完了までの一連の起動動作は環境ごとの受け入れ確認が必要です。

DNS・DHCP・IMDS、loopback、接続追跡済み通信の例外許可は、空 egress でも残ります。
許可された SSH 接続への応答や既存の HTTPS セッションではなく、新しい curl プロセスで外向き通信を確認してください。
DNS の失敗は HTTPS 遮断と区別します。必要なら、疎通可能時に確認した IP を curl の `--resolve example.com:443:<IP>` に指定して比較します。

## 5. 本番 AWS に適用する

本番では、ローカル用の既定ルール削除処理は実行しません。必要な送信ルールを Terraform で明示して適用します。

```bash
devbox run tf:prd init -lockfile=readonly
devbox run tf:prd plan
# 接続先アカウントと変更内容を確認してから適用する
devbox run tf:prd apply
```

アカウント確認と認証の設定は、元の検証環境の `README.md` にある「実 AWS への接続と plan」に従ってください（このリポジトリには未収録）。
`modules/` の編集は両環境の希望設定に影響しますが、`devbox run tf` が適用するのはローカルだけです。本番への適用は `tf:prd` で別途行います。

本番でも、適用後の SG API と EC2 の初期化ログを確認します。
ローカルで nginx がインストールできることだけを本番構築の成功条件にしないでください。
egress が空の構成では外部リポジトリへの新規 HTTPS 通信を遮断するため、起動時インストールが必要なら、起動前から443を許可します。
SG の許可に加えて、サブネットの経路、必要に応じたパブリック IP / NAT、DNS なども成立している必要があります。

## 6. 設定変更・再構築

| 操作 | 実施すること |
| --- | --- |
| 同じ SG で443を追加・削除 | Terraform を変更して apply。API と新規通信を再確認 |
| SG を新規作成・再作成 | ローカルでは3.2～3.4節を実施し、既定ルールを再確認・削除 |
| EC2 のみ置換 | SG の実際の egress を先に確認。置換後の EC2 ID を取り直す |
| Floci / Provider の更新 | 空 egress・443のみの両条件を確認。互換性対応が不要と確認できてから削除処理を外す |

nginx がすでにインストールされている EC2 は、egress を空にしても未インストールには戻りません。
起動時のインストールを再検証する場合は、SG の状態を確認したうえで EC2 を置換します。EC2 内のデータは失われます。

```bash
devbox run tf plan -replace=module.infrastructure.aws_instance.main
devbox run tf apply -replace=module.infrastructure.aws_instance.main
```

自動構築でも「SG 作成 → 既定ルール削除 → API 検証 → EC2 作成」の順を守ります。
削除 API の成功レスポンスだけではなく、Describe API が意図するルールになったことを次工程へ進む条件にしてください。

## 7. トラブルシューティング

| 症状 | 確認と対処 |
| --- | --- |
| state は空なのに外部通信できる | SG API の既定ルールを確認し、3.3節で削除。EC2 に付く他の SG も確認 |
| 443だけ許可したのに80にも接続できる | API と nftables に全送信許可が残っていないか確認 |
| 削除 API が成功したのにルールが残る | ポート未設定の既定ルールに対して、削除要求でポート0を指定していないか確認 |
| API は期待どおりだが通信結果が異なる | EC2 に付いている SG、対象コンテナ、nftables、既存接続の再利用を確認 |
| 443を許可しても dnf が失敗する | DNS、IPv4 / IPv6、経路、TLS、リポジトリを切り分ける |
| HTTPS は成功するが nginx がない | user_data の実行・終了結果を確認。通信許可だけではインストールは再実行されない |

## 関連資料

- 元の検証環境の環境構築手順: `README.md`（このリポジトリには未収録）
- 元の検証環境の互換性問題の根拠・検証ログ: `investigation/sg-egress-20261026/README.md`（このリポジトリには未収録）
- [AWS Security group rules](https://docs.aws.amazon.com/vpc/latest/userguide/security-group-rules.html)
- [Floci EC2](https://floci.io/floci/services/ec2/#security-group-port-publishing)
