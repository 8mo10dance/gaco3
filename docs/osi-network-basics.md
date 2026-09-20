# OSI参照モデルとネットワーク基礎

ネットワーク通信を理解するには、「誰に届けるか」「どの機器を経由するか」「安全に届けるか」という責務を分けて考えると分かりやすい。この文書では、OSI参照モデルからAWS、HTTP/3・QUIC、TLSまでを一本の流れとして整理する。

## 1. OSI参照モデル

OSI参照モデルは、ネットワーク通信に必要な役割を7つのレイヤーに分けて考えるための概念モデルである。

| Layer | 名称 | 主な役割 | 代表例 |
|---|---|---|---|
| L7 | アプリケーション層 | アプリケーション間の通信 | HTTP, DNS, SMTP |
| L6 | プレゼンテーション層 | データ表現・暗号化・圧縮 | 文字コード、暗号化 |
| L5 | セッション層 | 一連の通信・会話の管理 | セッション管理 |
| L4 | トランスポート層 | プロセス間通信 | TCP, UDP |
| L3 | ネットワーク層 | ホスト・ネットワーク間通信 | IP |
| L2 | データリンク層 | 同一ネットワーク内の通信 | Ethernet, MAC |
| L1 | 物理層 | 信号の伝送 | 電気、光、電波 |

```text
L7  アプリケーション ── アプリケーション寄り
 :
L1  物理             ── ハードウェア寄り
```

重要なのは、OSI参照モデルが「実際のプロトコルを厳密に7つの箱へ入れるための規則」ではなく、**通信に必要な責務を分離して理解するためのモデル**だということ。現実のTCP/IPやQUICは、OSIの境界と完全には一致しない。

## 2. L2・L3・L4の違い

通信相手を特定する粒度は、下位層から上位層へ進むほど細かくなる。

```text
L4  Process → Process     ポート番号
L3  Host    → Host        IPアドレス
L2  Interface → Interface MACアドレス
L1  実際の信号
```

### L3: どのホストへ届けるか

IPアドレスを使い、どのホスト・ネットワークへパケットを届けるかを扱う。

```text
Client → Router → Router → Server (192.0.2.10)
```

途中のルーターが見る主な情報は宛先IPアドレスであり、「宛先IPへ行くには次にどこへ送るか」をルーティングテーブルで決める。

### L4: どのプロセスへ届けるか

一台のサーバーでは複数のプロセスが動くため、IPアドレスだけでは届け先を決めきれない。

```text
Server: 192.0.2.10

:22    SSH
:443   HTTPS
:3306  MySQL
```

TCP/UDPはポート番号により、そのホスト上のどのプロセスへ渡すかを決める。TCPはさらに、順序制御・再送・フロー制御・輻輳制御により、信頼性のあるバイトストリームを提供する。UDPはプロセスへの配送を提供する一方、再送や順序保証は行わない。

L3とL4を分ける理由は、途中のルーターが「宛先サーバー上のどのアプリケーションか」を知らなくてもよいようにするためでもある。ルーターはホストまでの経路だけを扱い、到着先ホストがポート番号を見てプロセスへ配送する。

## 3. セッション層

セッション層は、複数回の通信を「一連の会話」として管理する責務を表す。

```text
              Session A
┌─────────────────────────────────┐
│ TCP connection 1 → 切断          │
│ TCP connection 2 → 処理を継続    │
└─────────────────────────────────┘
```

TCP接続とセッションは概念的に別物である。TCP接続が切れても、アプリケーションは同じログイン状態や同じアップロード処理の続きとして扱うことがある。現代のTCP/IPではOSIのL5が独立して実装されることは少なく、多くはアプリケーション側へ吸収されている。Webアプリケーションの「session」も考え方は近いが、OSIのL5そのものではない。

## 4. リピータ・スイッチ・ルーター

### リピータ

リピータはL1で動作する。IPやMACを理解せず、弱くなった物理信号を中継・再生する。

### ブリッジ / スイッチ

ブリッジやL2スイッチはMACアドレスを見て、Ethernetフレームをどのポートへ送るか決める。現代では、多数のポートを持つブリッジとしてスイッチが一般的である。

```text
             Switch
         ┌─────┼─────┐
        PC-A  PC-B  PC-C

MAC address             Port
AA:AA:AA:AA:AA:AA  →    1
BB:BB:BB:BB:BB:BB  →    2
```

宛先MACのポートが分かればそのポートにだけ転送する。まだ学習していないMACアドレスなら、必要なポート群へフラッディングする。

### ルーター

ルーターはL3で動作し、異なるIPネットワーク間でパケットを転送する。

```text
192.168.1.0/24 ── Router ── 192.168.2.0/24

eth0: 192.168.1.1/24
eth1: 192.168.2.1/24
```

例えば、次のようなルーティングテーブルを持つ。

```text
192.168.1.0/24 → eth0
192.168.2.0/24 → eth1
0.0.0.0/0      → 次のRouter
```

宛先が`192.168.2.20`なら、`192.168.2.0/24`の経路に一致するため、ルーターは`eth1`から送信する。

### ルーターとスイッチの分業

```text
Router:  宛先IPを見て「どのネットワーク・次ホップへ送るか」を決める
Switch:  宛先MACを見て「どのポートへ流すか」を決める
Physical: 実際にその線・電波へ信号を流す
```

両者とも出口を選ぶが、ルーターはIPによるネットワーク間の転送、スイッチはMACによる同一ネットワーク内の転送を扱う。

## 5. ARP

ARP（Address Resolution Protocol）は、IPv4アドレスからMACアドレスを調べる仕組みである。

```text
ARP Request: 「192.168.2.20のMACアドレスを教えて」
ARP Reply:   「MACはAA:BB:CC:DD:EE:FF」
```

得られた対応関係はARPキャッシュ（neighbor table）に一定時間保存される。

別ネットワークの宛先へ送る場合、端末がARPで調べるのは最終目的地のMACアドレスではない。まずルーティングにより「デフォルトゲートウェイへ送る」と決め、その**次ホップであるデフォルトゲートウェイのMACアドレス**をARPで求める。

```text
PC → 8.8.8.8
  → 別ネットワーク
  → Default GatewayのMACをARPで取得
  → GatewayへEthernetフレームを送る
```

つまり、役割は次の通り。

```text
Routing: 「次に渡すIPは誰か」
ARP:     「そのIPのMACアドレスは何か」
Ethernet:「そのMACアドレスへ送信する」
```

## 6. ルーターのインターフェース

基本的には、ルーターの物理ポートごとにネットワークインターフェースを持たせられる。

```text
             Router
  port 1                 port 2
192.168.1.1/24         192.168.2.1/24
    │                       │
 Switch A                Switch B
    │                       │
  LAN A                   LAN B
```

ケーブルを挿したからIPアドレスが決まるのではなく、そのインターフェースにIPアドレスと所属ネットワークを設定する。

また、ネットワークインターフェースと物理ポートは常に1対1ではない。VLANなどを使えば、一本の物理ポート上に複数の論理インターフェースと論理ネットワークを構成できる。

```text
Physical Port
  ├─ Logical Interface A: 192.168.1.1
  └─ Logical Interface B: 192.168.2.1
```

## 7. Gatewayという概念

Gatewayだけは、リピータ・スイッチ・ルーターと同じ分類軸ではない。

```text
Repeater  → L1の機能をする装置
Switch    → L2の機能をする装置
Router    → L3の機能をする装置
Gateway   → 異なる領域の境界・入口という役割
```

Gatewayは特定のOSIレイヤーを意味しない。例えば家庭や社内LANでは、外部ネットワークへ送るルーターが、端末から見ればデフォルトゲートウェイでもある。

> Routerは「何をするか」を表す概念で、Gatewayは「どのような立場にいるか」を表す概念。

広い意味では、ルーターはゲートウェイとして働き得る。ルーターは同じIPの世界で経路選択・転送を行う。より一般的なゲートウェイは、必要に応じてプロトコルやデータ形式を変換して、異なる世界の境界を橋渡しすることもある。

したがって、`Repeater → Switch → Router → Gateway`をOSIの階層として覚えるのは適切ではない。Gatewayはこの縦軸から外して理解すると混乱しない。

## 8. AWSのGateway

AWSでもGatewayは広い意味で使われ、対象と役割はそれぞれ異なる。

| 種類 | 主な役割 |
|---|---|
| Internet Gateway | VPCとインターネットの境界 |
| NAT Gateway | Private Subnetからの外向き通信を可能にする |
| Transit Gateway | 複数VPC・オンプレミス接続を集約するネットワークハブ |
| Virtual Private Gateway / Customer Gateway | AWSとオンプレミス間のVPN接続で使う境界要素 |
| Egress-only Internet Gateway | IPv6の外向きインターネット接続 |
| API Gateway | HTTP/APIの公開・管理の入口 |
| Storage Gateway | オンプレミスとAWSストレージの橋渡し |

### Internet Gateway

```text
Internet ↔ Internet Gateway ↔ VPC

10.0.0.0/16 → local
0.0.0.0/0   → Internet Gateway
```

Internet GatewayはVPCとインターネットの境界となる。

### NAT Gateway

```text
Private Subnet → NAT Gateway → Internet Gateway → Internet
```

Private Subnet内のリソースが外部へ接続できるようにする一方、インターネット側からPrivate Subnetのリソースへ直接接続する構成にはしない。

### Transit Gateway

```text
       VPC-A
         │
VPC-B ─ TGW ─ VPC-C
         │
    On-premises
```

Transit Gatewayは、複数VPCやオンプレミス接続を集約する大規模なネットワークハブ・ルーターのような役割を果たす。

## 9. ALBとAPI Gateway

両方ともHTTPのリクエストを条件に応じて振り分けられるが、主目的が異なる。

### ALB

Application Load Balancer（ALB）の主目的は、リクエストを複数のバックエンドへ分散すること。

```text
Client → ALB → App / App / App
```

L7の情報を使うため、`/api/*`をTarget Group Aへ、`/images/*`をTarget Group Bへ、といったHTTPルーティングもできる。

### API Gateway

API Gatewayの主目的は、APIをどのように外部公開・管理するかである。

```text
Client → API Gateway → Backend
             ├─ Authentication
             ├─ API Key
             ├─ Throttling / Rate Limit
             ├─ Quota
             └─ Monitoring
```

要するに、ALBは「どのバックエンドへ流すか」、API Gatewayは「このAPIを誰に、どの条件で使わせるか」により重心がある。単純なWebアプリなら`Internet → ALB → ECS / EC2 → Rails`だけで十分なことも多い。一方、外部公開APIや複数サービスで共通認証・APIキー・レート制限・クォータを入口に集約したいならAPI Gatewayが有効である。

## 10. AWSのENI

ENIはElastic Network Interface、AWS上の仮想NICである。

```text
物理環境: Computer → NIC (eth0) → Network
AWS:     EC2      → ENI        → Subnet
```

ENIには、Private IP、MACアドレス、Security Group、Subnetとの所属関係などが紐づく。

> IPアドレスはEC2そのものではなく、基本的にはネットワークインターフェースであるENIに付いている。

この見方をすると、仮想ネットワーク上の接続や移動を理解しやすい。

## 11. ファイルアップロードとTCP

ファイルアップロードそのものがTCPなのではない。HTTP/1.1やHTTP/2で画像をアップロードする場合、典型的には次の構造になる。

```text
画像ファイル → HTTP → TCP → IP → Ethernet / Wi-Fi
```

TCPにとってファイルは単なるバイト列である。TCPは、そのバイト列を順番どおり、欠けないように相手へ渡すための仕組みを提供する。

ただし、ファイル転送が必ずTCPというわけではない。HTTP/3では、HTTPはQUICを使い、QUICはUDP上で動く。

```text
HTTP/1.1, HTTP/2 → TCP → IP
HTTP/3           → QUIC → UDP → IP
```

本質的に必要なのはTCPそのものではなく、最終的に正しいデータを相手へ届ける仕組みである。

## 12. QUICとHTTP/3

QUICはOSI参照モデルにきれいに当てはめにくいが、概念的にはL4（トランスポート層）相当の仕事をする。

```text
HTTP/3  ← L7
  ↓
QUIC    ← L4相当
  ↓
UDP     ← L4
  ↓
IP      ← L3
```

UDPを土台として使いつつ、UDPにはない以下の機能をQUIC自身が提供する。

- コネクション管理
- 信頼性・再送
- 輻輳制御
- 複数ストリーム
- TLS 1.3による暗号化
- Connection ID

### QUICを使う理由

#### Head-of-Line Blockingの軽減

HTTP/2は複数ストリームを一本のTCP接続へ流す。TCPは順序付きの一つのバイトストリームなので、途中でパケットが失われると、関係のない後続ストリームもアプリケーションへ渡すまで待たされ得る。

```text
HTTP/2: Stream A / B / C → TCPの一本のバイトストリーム
QUIC:   Stream A（待機）とStream B・C（継続可能）を分離できる
```

#### 接続開始の効率化

TCP + TLSでは、TCP接続の確立後にTLSハンドシェイクを行う。QUICはTLS 1.3を統合しており、接続確立を効率化できる。

#### Connection Migration

TCP接続はIPアドレスとポートの組に強く結びつく。QUICはConnection IDを持つため、Wi-Fiから5Gへ切り替わるなどIPアドレスが変わる場面でも接続を継続しやすい。

#### 進化させやすさ

TCPはOS、NAT、Firewall、Load Balancerなど世界中のインフラに深く組み込まれており、挙動を変えるのは難しい。QUICは既存ネットワークからUDPとして見える形で、トランスポート機能をより更新しやすい位置に実装している。

したがってQUICは単に「TCPより速いプロトコル」ではなく、TCPが担ってきた機能を現代のWeb向けに再設計し、進化させやすい場所に移したものと捉えると分かりやすい。

## 13. TLS

TLS（Transport Layer Security）は、通信を盗聴・改ざん・なりすましから保護する仕組みである。HTTPSでは通常、次のように重なる。

```text
HTTP → TLS → TCP → IP
```

TLSが主に提供するものは3つ。

1. **機密性**: 通信内容を暗号化し、第三者に読まれないようにする。
2. **完全性**: 通信途中でデータが書き換えられたことを検出する。
3. **認証**: 通信相手が本物のサーバーかを確認する。証明書とCAによる信頼の連鎖を用いる。

通信開始時のTLSハンドシェイクでは、クライアントとサーバーが対応方式を確認し、サーバー証明書を検証し、鍵共有を通じて共通のセッション鍵を導出する。大量のデータ暗号化には高速な共通鍵暗号を利用する。

```text
Client                         Server
ClientHello ─────────────────→
            ←─ ServerHello / Certificate
      鍵共有・認証
      共通のセッション鍵を導出
      暗号化通信を開始
```

## 14. TLS Termination

AWSではALBでTLSを終端する構成がよく使われる。

```text
Browser ── HTTPS ──> ALB ── HTTP または HTTPS ──> Rails
```

TLS Terminationとは、ALBなどの入口がクライアントとのTLS接続を復号することを指す。これによりアプリケーションサーバーは証明書管理や暗号処理を直接担わずに済み、ロードバランサーで証明書更新・暗号設定を集約できる。

ただし、ALBからバックエンドまでHTTPにする場合、その区間は平文になる。VPC内で閉じた通信として設計することは多いが、要件に応じてALBからバックエンドもHTTPSにし、再暗号化する構成を選ぶ。

## 15. 全体像

ブラウザからAWS上のアプリケーションへHTTPSリクエストを送る例を、各要素の役割で追う。

```text
Browser
  │  HTTP request
  │  TLSで暗号化
  │  TCP または QUICで配送を制御
  │  IPで宛先ネットワークへ運ぶ
  ▼
家庭・社内LANのDefault Gateway（多くはRouter）
  │  宛先IPにより次ホップを選ぶ
  ▼
Internet / AWS Internet Gateway
  ▼
ALB（TLS Termination、L7ルーティング・負荷分散）
  ▼
EC2 / ECSのENI
  ▼
アプリケーション（例: Rails）
```

同一LAN内では、IPによる次ホップ選択とARPによるMACアドレス解決を経て、スイッチがMACアドレスに応じて適切なポートへフレームを流す。ネットワークをまたぐたびにL2のフレームは次ホップ向けに作り直される一方、基本的にはL3の宛先IPを手がかりにルーターが転送を続ける。

この全体を一言で言えば、下位層は「次の区間へどう送るか」を担い、上位層になるほど「誰のどの処理へ、どんな意味のデータを、安全に届けるか」を担う。OSI参照モデルは、その分業を見通しよくするための地図である。
