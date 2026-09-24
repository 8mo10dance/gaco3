# ALB 導入から学ぶ AWS 通信・運用・Terraform

ALB（Application Load Balancer）を EC2 上の nginx の前段に置くと、利用者への公開窓口とアプリケーションサーバーを分離できる。このノートでは、通信経路、責務の分け方、障害の切り分け、既存リソースの Terraform 化を、導入後にも参照しやすい形で整理する。

## 1. まず全体の通信経路を捉える

典型的な HTTP 公開では、通信は次の順番で流れる。

```text
Internet
   ↓
ALB listener
   ↓
target group
   ↓
EC2
   ↓
nginx
   ↓
Web application / static files
```

各段階が独立した責務を持つため、障害時は「どこまで到達したか」を順に確認できる。ALB は EC2 自体を直接ルールの宛先にするのではなく、target group を宛先として listener rule に関連付ける。

## 2. ALB を構成する要素と役割

### ALB

ALB は HTTP/HTTPS のリクエストを受け、条件に応じて target group へ振り分けるロードバランサーである。複数の EC2、ECS のタスクなどへ振り分けることもできる。TLS を ALB で終端する、ホスト名やパスで行き先を変える、といった入口の責務も担う。

### Listener

Listener は ALB が待ち受けるプロトコルとポート、および受けたリクエストへの初期動作を定義する。

```text
HTTP :80   → target group へ forward
HTTPS :443 → 証明書で TLS を終端して target group へ forward
```

Listener rule を使うと、例えば `/api/*` と `/images/*` を別々の target group へ振り分けられる。

### Target group

Target group は ALB が転送先として扱う対象の集合である。target の種別や、ALB から target へ接続するプロトコル・ポートをここで定める。EC2 を target にした場合、各インスタンスが登録され、health check の結果に基づいて転送対象になる。

### Health check

Health check は、target group 内の各 target に ALB から定期的にリクエストを送り、実際にリクエストを処理できるかを判定する仕組みである。成功とみなす HTTP ステータス、確認パス、間隔、しきい値を設定する。

正常な応答を返せない target は unhealthy となり、ALB は通常その target へ新しいリクエストを転送しない。したがって health check のパスは、nginx とアプリケーションを経由して正常性を表せる、安定したエンドポイントを選ぶ。

## 3. 利用者側と内部側のプロトコルは分けられる

通信を二つの区間に分けると考える。

```text
利用者 ── HTTPS :443 ──> ALB ── HTTP :80 / :8080 ──> EC2
```

利用者から ALB までは HTTPS、ALB から EC2/nginx までは HTTP のように、区間ごとにプロトコルとポートを分けられる。これは ALB で TLS を終端する構成でよく使われる。内部区間にも暗号化が必要な要件がある場合は、ALB から target への接続を HTTPS にすることもできる。

どちらを選ぶかは「ALB までの暗号化で要件を満たすか」「VPC 内の経路でも暗号化が必要か」を分けて判断する。ALB を置いただけで、すべての区間が自動的に HTTPS になるわけではない。

## 4. Security Group で入口を一つに絞る

ALB と EC2 には別の Security Group（SG）を付け、許可する送信元を段階的に狭める。

```text
Internet
   ↓ HTTPS :443 / HTTP :80 を許可
ALB security group
   ↓ target port を許可
EC2 security group
```

- ALB 側 SG: 利用者に公開するポート（例: `80`、`443`）を必要な送信元から許可する。
- EC2 側 SG: nginx またはアプリケーションが待ち受けるポートを、CIDR ではなく **ALB 側 SG を送信元として**許可する。

この設定では、利用者が EC2 の公開 IP とポートを直接指定しても到達できず、正規の経路は `Internet → ALB → EC2` に限定される。EC2 の target port を `0.0.0.0/0` に開けたままにすると、この分離は成立しない。

## 5. 画面が想定どおりでないときの切り分け

HTTP ステータスや表示内容は、どの層が応答を返したかを示す手掛かりになる。まずブラウザの開発者ツールや `curl` で、URL、ステータス、レスポンスヘッダー、本文を確認する。

| 現象 | 主に確認する層 | 確認の観点 |
|---|---|---|
| `503 Service Unavailable` | ALB / target group | healthy な target があるか、health check のパス・ポート・成功コード、EC2 側 SG を確認する。 |
| `504 Gateway Timeout` | ALB → EC2 の通信またはバックエンド処理 | target port へ到達できるか、nginx・アプリケーションが応答しているか、ALB の待機時間内に応答できるかを確認する。 |
| nginx のデフォルト画面 | EC2 / nginx | ALB から nginx までは到達している可能性が高い。`server_name`、default server、`root`、`proxy_pass`、配置済みのコンテンツを確認する。 |
| 修正後も古い画面が出る | ブラウザ、CDN、経路全体 | ブラウザのキャッシュを無効化または強制再読み込みし、`curl` でも同じ応答かを比べる。CloudFront などが前段にあれば、そのキャッシュも別途確認する。 |

`503` と `504` を「ALB の故障」と一括りにせず、target が選べない状態なのか、選ばれた target の応答待ちなのかを区別する。nginx のデフォルト画面は、ネットワークの到達性ではなく nginx の仮想ホスト設定やコンテンツ設定に原因がある場合の有力な手掛かりである。

## 6. HTTPS と ACM 証明書の前提

ACM で発行したパブリック証明書は、ALB で利用する用途であれば証明書料金なしで利用できる。ただし HTTPS を独自の名前で提供するには、その名前を管理している必要がある。

```text
example.com
  ↓ DNS validation などで所有を証明
ACM certificate
  ↓
ALB HTTPS listener :443
```

ALB に AWS が割り当てる DNS 名は利用者の独自ドメインではないため、通常はその名前に対する ACM パブリック証明書を発行できない。学習用に ALB の AWS 提供 DNS 名で HTTPS の動作を確認したい場合と、本番の独自ドメインで HTTPS を提供したい場合は、前提が異なることを意識する。

## 7. CloudFront + S3 から ALB + EC2 へ移行するときの注意

静的サイトの構成を次のように置き換えることがある。

```text
Before: Browser → CloudFront → S3
After:  Browser → ALB → EC2 → nginx
```

この変更は origin を差し替えるだけではない。CloudFront + S3 で得ていた次の性質は、ALB + EC2 に自動では引き継がれない。

- CloudFront による CDN 配信、エッジキャッシュ、キャッシュ制御
- CloudFront 経由の HTTPS 提供や独自ドメインの証明書設定
- S3 の静的ファイル配信、OAC などの origin へのアクセス制御

移行前に、HTTPS、独自ドメイン、キャッシュ、可用性、静的アセットの配信性能、アクセス制御といった非機能要件を一覧にし、どのサービスで満たすかを再設計する。例えば CloudFront を残して ALB を origin にすれば、CDN を維持しつつ動的なバックエンドへ接続できる。

## 8. コンソールで作成したリソースを Terraform に取り込む

コンソールで先に ALB、listener、target group、SG などを作成した場合、Terraform の設定と state と実環境の対応を意識して取り込む。

### state を先に確認する

最初に、対象がすでに state で管理されていないかを確認する。

```bash
terraform state list
terraform state show aws_lb.example
```

state に既に存在するリソースを別アドレスへ import すると、同じ実リソースを重複して管理しようとしてしまう。設定中の resource address と state の address を照合する。

### import は未管理の実リソースを state に関連付ける

Terraform 管理下にない既存リソースは、`import` block または `terraform import` で、実リソース ID と resource address を関連付ける。

```hcl
import {
  to = aws_lb.example
  id = "app/my-alb/xxxxxxxx"
}
```

import 後も、設定が実際の属性を十分に表していなければ `plan` に差分が出る。差分を読み、設定を整えるか、実環境を変更するかを意図して決める。

### moved は Terraform 内のアドレス変更を宣言する

resource をモジュールへ移動するなど、すでに Terraform が管理している resource address を変えるときは `moved` block を使う。

```hcl
moved {
  from = aws_lb.example
  to   = module.web.aws_lb.this
}
```

`moved` は外部に存在する未管理リソースを取り込むためのものではない。使い分けは次のとおりである。

| 状況 | 使うもの |
|---|---|
| AWS にあるが Terraform state にないリソースを管理し始める | `import` |
| state 管理中の resource の Terraform address を変更する | `moved` |
| どちらに当たるか不明 | `terraform state list` / `terraform state show` で現状を確認する |

## 9. Terraform の変更前に確認すること

変更を適用する前に、構文・設定・差分を順に確認する。

```bash
terraform fmt -check
terraform validate
terraform plan
```

- `terraform fmt -check`: HCL の整形が期待どおりかを確認する。
- `terraform validate`: 設定の構文や内部的な参照関係を確認する。
- `terraform plan`: 実環境と state を比較し、適用時の操作を確認する。

特に `plan` では、`add`、`change`、`destroy`、`import` のすべてが意図どおりかを確認する。予定していない `destroy`、既存リソースの置換、異なるリソースへの import が含まれていれば、apply の前に resource address、依存関係、import ID、`moved` の指定を見直す。

## 10. 導入・変更時の確認順序

最後に、構成を変更したときは次の順で確認すると、層を飛ばさずに原因を絞り込みやすい。

1. ALB listener が公開ポートでリクエストを受けられるか。
2. listener rule が意図した target group へ forward しているか。
3. target group の target が healthy か。
4. EC2 側 SG が ALB 側 SG からの target port だけを許可しているか。
5. nginx が意図した virtual host、コンテンツ、または upstream を返しているか。
6. ブラウザ、CloudFront などのキャッシュを除外しても同じ応答か。
7. Terraform の `fmt`、`validate`、`plan` で、インフラ定義と実環境の差分が意図どおりか。

この順序は、通信の入口からアプリケーション、さらに IaC の管理状態へ進む。現象だけでなく、各層の責務と設定を対応付けて記録・確認することで、ALB 構成を安全に変更しやすくなる。
