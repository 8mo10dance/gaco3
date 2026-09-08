# Proton、Solid / Inrupt、EUデータ政策の整理

> 作成日: 2026-09-08  
> 対象: Proton、Tim Berners-Lee の Solid、Inrupt、European Data Spaces、Data Sovereignty、Data Governance、MyData

## 要約

Proton と Solid / Inrupt は、いずれも「個人がデータをコントロールできるインターネット」を志向する。ただし、解こうとしている問題の層が異なる。

| 観点 | Proton | Solid / Inrupt |
| --- | --- | --- |
| 主な問題設定 | 巨大プラットフォームにデータを預けすぎること | アプリ事業者が利用者データを抱え込む Web の構造 |
| アプローチ | プライバシー重視の代替サービス群を提供 | アプリとデータを分離する標準・基盤を提供 |
| 例 | Proton Mail / VPN / Drive / Calendar / Pass | Pod、Wallet、アクセス許可、企業向けサーバー |
| 主な顧客・利用者 | 個人・組織のサービス利用者 | Solid 対応アプリを作る企業・政府・開発者、およびその利用者 |
| データの置き場所 | Proton のサービス基盤（暗号化を重視） | 利用者・組織ごとの Pod / Wallet。アプリは許可を得てアクセス |

Proton は「信頼できる保管・通信サービスを選べるようにする」モデル、Solid は「アプリとデータ保管先を別々に選べるようにする」モデルである。両者は競合というより、データ主権を実現する別レイヤーの取り組みと考えると分かりやすい。

## 1. Proton

Proton は、CERN で出会った科学者・技術者が 2014 年にスイスで始めた、プライバシーとデジタル自由を前面に置くサービス事業者である。Proton AG の主要株主はジュネーブの非営利 Proton Foundation で、広告やデータ販売ではなく利用者のサブスクリプションを収益源とすると説明している。

主なサービスは Mail、VPN、Drive、Calendar、Pass、Docs / Meet 等である。全体として「広告ターゲティングのために利用者データを集める」モデルの代替を、暗号化とサブスクリプションで提供する構図である。

- Proton は「誰にもデータを渡さない」と法的に約束できる存在ではなく、スイス法の有効な命令には従う必要がある。
- サービス設計上は、Proton が復号できないデータを増やすこと（ゼロアクセス暗号化など）を重視する。
- データの保管先は依然として Proton のサービスであり、任意の他社アプリが同じ個人データを標準的に読み書きする仕組みを作ることが主目的ではない。

**公式資料:** [Proton: About](https://proton.me/about)、[Proton Foundation](https://proton.me/foundation)、[Proton 利用規約](https://proton.me/legal/terms)

## 2. Solid：Web における「データとアプリの分離」

Tim Berners-Lee が進めた Solid は、現在の Web で一般的な「アプリケーションがデータを自社データベースに閉じ込める」前提を変えようとする。Solid は特定の一社のクラウドではなく、既存 Web 技術の上に、データの保存・識別・アクセス制御の共通ルールを加えるオープンな仕様／エコシステムである。

```text
従来

アプリ A ──> A 社のデータベース
アプリ B ──> B 社のデータベース

Solid の目標像

アプリ A ─┐
アプリ B ─┼──> 利用者または組織の Pod
AI Agent ─┘          └── 本人・所有者がアクセスを制御
```

- **Pod（Personal Online Datastore）**: Solid 上でデータを置く場所。利用者は一つまたは複数の Pod を持て、アプリは許可された範囲でリソースを読み書きする。
- **WebID**: 人、組織、アプリなどを識別する URI。Pod と同一のものではなく、アクセス許可の対象を表す際などに使う。
- **相互運用性**: 対応アプリは特定一社の Pod に縛られず、対応する別の Pod provider とも動くことを目指す。
- **技術的な性格**: ブロックチェーンを必須とせず、HTTP、Linked Data / RDF、OIDC など既存 Web 標準の延長にある。

標準があるだけでデータの意味が自動的に揃うわけではない。アプリ間で再利用するには、データ形式・語彙・同意画面・責任分界を揃える必要がある。また、一度第三者に正当に読まれたデータの複製まで技術的に防止できるわけではない。

**公式資料:** [Solid Project FAQ](https://solidproject.org/faq)、[Solid 開発の始め方](https://solidproject.org/for_developers/getting_started)

## 3. Inrupt：Solid を企業・政府で使える基盤へ

Inrupt は Tim Berners-Lee と John Bruce により、Solid の商用・組織利用を進めるために 2018 年に公開・設立された会社である。Solid 自体はオープンな標準・プロジェクトであり、Inrupt は唯一の実装者ではない。一方で Inrupt は、Solid 仕様を実装・拡張した企業向けの製品、SDK、運用支援を提供している。

| 用語 | 役割 | 注意点 |
| --- | --- | --- |
| **Solid Pod** | 個人または組織のデータを置く、標準準拠の保管領域 | Pod は概念／標準上の保存先で、Inrupt 製品に限定されない。 |
| **Data Wallet / Solid Data Wallet** | データを保管・管理し、同意に基づいて共有する利用者向けの器・体験 | Inrupt は Wallet を Pod 上のユーザー中心のデータ管理として説明する。 |
| **Wallet Infrastructure** | Wallet を支える認証・認可、API / SDK、運用・コンプライアンス用の基盤 | 高規制業界など組織利用を意識する。 |
| **Enterprise Solid Server（ESS）** | 組織が Pod / Wallet storage を大規模に運用するサーバー | Inrupt の商用製品。 |
| **PodSpaces** | ESS のホスト型開発環境 | Developer Preview で、機密・個人データや本番利用向けではない。 |
| **Agentic Wallets** | AI エージェントが本人の同意を得たデータだけを扱う Wallet 中心の構想 | 実装範囲は個別製品・契約で確認が必要。 |

ESS は、Pod のライフサイクル、認証、認可、データ管理、通知、監査、問い合わせ等を扱う。組織は自社クラウドまたはオンプレミスに展開でき、既存の OIDC 準拠 IdP と接続できる。

```text
アプリ／AI Agent
     │  アクセス要求
     ▼
本人・組織の同意とポリシー
     │  許可（必要なら後から撤回）
     ▼
ESS 上の Pod / Wallet storage
```

アクセス制御では、アプリや組織がデータへのアクセスを要求し、Pod / Wallet の所有者が許可・拒否・撤回する。Inrupt の **Access Grant** は、特定のアクセス権を表す検証可能な資格情報の形を取る。

Inrupt は近年、Pod という技術語に加え **Data Wallet** を前面に出している。**Agentic Wallets** は、AI が個人データを無制限に収集するのではなく、誰のどのデータを、どの目的の AI に、いつまで渡すかを可視化・制御可能にする考え方である。2026 年時点の ESS 3.0 は MCP Server を導入し、MCP 対応 AI agent が消費者ごとのデータ保管領域に標準プロトコルで接続できるとしている。

**公式資料:** [Inrupt: About](https://www.inrupt.com/about)、[Key Concepts](https://docs.inrupt.com/getting-started/key-concepts)、[ESS introduction](https://docs.inrupt.com/ess/2.3/introduction)、[Universal Data Wallet Infrastructure](https://www.inrupt.com/release/data-wallet)、[ESS 3.0 と AI / MCP](https://www.inrupt.com/release/ess-version-3-0-making-consumer-data-ready-for-ai-assistants)

## 4. Proton と Solid / Inrupt の違い

両者は「本人を中心に置く」「大量のデータ収集に依存するビジネスモデルを問い直す」という点で重なる。しかし、Proton は**サービス提供者として信頼性・暗号化・ガバナンスを実装**し、Solid / Inrupt は**データ所有とアプリ利用の関係を標準と基盤で組み替える**。

| 問い | Proton の答え | Solid / Inrupt の答え |
| --- | --- | --- |
| メールやファイルはどこに置くか | Proton のプライバシー重視サービス | 利用者／組織が選ぶ Pod / Wallet に置き、対応アプリが利用する |
| 誰がデータ利用を決めるか | Proton のサービス機能・暗号化・ポリシーの中で利用者を保護 | Pod / Wallet の所有者がアプリ・組織・AI ごとに許可を管理する |
| 価値の中心 | セキュアで実用的なアプリ群 | データ可搬性・相互運用性・細粒度の同意を可能にする基盤 |
| 普及上の鍵 | サービス品質、信頼、価格、使いやすさ | 対応アプリ、共通データモデル、ガバナンス、エコシステム参加者の連携 |

理論上は、Proton のようなプライバシー志向サービスが Solid 対応のデータ利用者／保管先になることもあり得る。ただし、現時点で Proton が Solid の Pod を主要サービスとして採用しているという意味ではない。

## 5. Inrupt / Solid の導入・実証例

Solid の導入事例は、一般消費者向けの公開体験、組織内・業界内の実装、PoC が混在する。「企業全体の主要データ基盤が全面的に Solid 化された」とは限らない。

| 事例 | 概要 | 成熟度の読み方 |
| --- | --- | --- |
| **BBC Together + Data Pod** | 共同視聴の文脈で、利用者が自分のデータを管理・共有する考え方を示した。 | BBC 全サービスの標準基盤とみなすのは過大解釈。 |
| **BBC My PDS** | Spotify、Netflix、BBC 等の利用データを個人データストアへ集め、別サービスで利用する可能性を示した。 | アプリ横断データ利用の実験であり、ネイティブ連携の普及を示すものではない。 |
| **フランダース政府／athumi** | 市民・組織がデータを管理し、行政や人事・健康等の文脈で共有する取り組み。 | 対象者、アプリ、運用範囲は案件ごとに確認する。 |
| **Pluxee Belgium** | Healthy Lifestyle Wallet を含む、利用者中心のデータ共有・ウェルビーイングのユースケース。 | 顧客事例であり、現在の提供範囲は一次情報で確認する。 |
| **EverBetter / MaxWell Clinic** | 患者中心の EHR を目指す医療領域の事例。 | 臨床・法的な実装範囲は別途確認が必要。 |
| **NatWest、NHS** | 2020 年の ESS ベータ発表時に early adopter として言及された。 | 当時の早期導入・探索を示す資料。 |

評価する際は、Pod を使っただけか複数アプリが同じデータを再利用しているか、本人による許可・撤回が実運用にあるか、異なる組織・ベンダー間で相互運用できるか、PoC から基幹業務のどの段階かを確認する。

**関連資料:** [Inrupt ESS ベータ公開](https://www.inrupt.com/blog/inrupt-beta-live)、[athumi](https://athumi.eu/)、[Inrupt](https://www.inrupt.com/)

## 6. EU の European Data Spaces とデータ主権

EU の **European Strategy for Data（2020年）** は、データの単一市場を作り、欧州の競争力とデータ主権を高めることを掲げた。その実装の柱が **Common European Data Spaces** である。

Data Space は単一の巨大データベースを作る構想ではない。健康、農業、製造、エネルギー、モビリティ、金融、公共行政、スキル、オープンサイエンス、グリーンディール等の分野で、データ保有者が管理権を保ちつつ、安全・信頼できる条件でデータを発見・共有・再利用できるようにする、分散的なインフラとガバナンスの枠組みである。

```text
EU データ戦略
  ├─ 法制度: GDPR、Data Governance Act、Data Act など
  ├─ 共通基盤・支援: DSSC、SIMPL、標準化・相互運用性
  └─ 分野別 Data Spaces
       ├─ Health
       ├─ Mobility
       ├─ Energy
       ├─ Manufacturing
       ├─ Agriculture
       └─ Public administration / finance / skills / …
```

| 制度・概念 | 何を扱うか | Solid / MyData との接点 |
| --- | --- | --- |
| **GDPR** | 個人データ保護、本人の権利、処理の適法性 | 本人中心に扱う際の最低限の権利・義務の土台。 |
| **Data Governance Act（DGA）** | 保護された公的データの再利用、データ仲介、データ・アルトルイズム等 | 信頼できるデータ共有のガバナンスを補う。 |
| **Data Act** | IoT 等で生じるデータへの公正なアクセス・利用、クラウド切替等 | データ可搬性・相互運用性の制度面を強める。 |
| **Common European Data Spaces** | 分野ごとの安全で相互運用可能なデータ共有環境 | Solid は技術的選択肢になり得るが、EU の公式標準としての採用と同義ではない。 |
| **Data Sovereignty** | 個人・企業・公共機関が自らのデータの利用条件を制御できるという考え方 | Solid、MyData と方向性が重なる。 |
| **Data Governance** | アクセス、責任、品質、監査、ルール、紛争解決などを決める仕組み | Pod や API だけでは解決しない中核。 |

Data Spaces は分野横断の政策・ガバナンス・市場形成の枠組みであり、Solid は個人／組織のデータをアプリから分離して扱うための Web 技術・仕様である。Data Space の実現には、ID、契約、責任、データ品質、意味論、標準、競争法、監査等も必要で、Pod の導入だけでは足りない。

**EU 公式資料:** [A European strategy for data](https://digital-strategy.ec.europa.eu/en/policies/strategy-data)、[Common European data spaces](https://digital-strategy.ec.europa.eu/en/policies/data-spaces)、[Data Governance Act](https://digital-strategy.ec.europa.eu/en/policies/data-governance-act-explained)、[Data Act](https://digital-strategy.ec.europa.eu/en/factpages/data-act-explained)

## 7. MyData：人間中心のデータ利用という規範

**MyData** は、特定の製品やプロトコルではなく、個人が自分のデータを自律的に利用し、組織との力の非対称を減らし、データ利用を透明で人間中心にするための国際的な運動・原則群である。

個人にすべての運用負担を背負わせるのではなく、組織側の透明性、相互運用性、仲介、説明可能なルール、使いやすい同意管理によって、自己決定を実効的なものにする必要がある。

| 概念 | 主な焦点 |
| --- | --- |
| Solid | データ保管とアプリを分け、利用者がアクセスを選べる Web の技術モデル |
| Inrupt | Solid を企業・政府向けに運用する製品・基盤 |
| MyData | 人間中心の個人データ利用を実現するための原則・運動・実務コミュニティ |
| European Data Spaces | 分野ごとのデータ共有を、EU の制度・ガバナンス・相互運用性で進める政策的枠組み |

MyData は Solid を支持し得るが、Solid に還元されない。逆に Solid は MyData 的なデータ自己決定を実装する手段の一つだが、技術を入れただけで人間中心性が達成されるわけでもない。

**公式資料:** [MyData Global](https://mydata.org/)、[MyData Declaration](https://mydata.org/participate/declaration/)、[MyData Publications](https://mydata.org/publication/)

## 8. 学習ロードマップと資料

1. **Proton** — サービス事業者が「プライバシーをデフォルトにする」とは何かを掴む。
2. **Solid FAQ** — Pod、WebID、アプリとデータの分離を把握する。
3. **Inrupt ESS / Wallet** — Solid を組織で運用する場合の実装を知る。
4. **EU Data Strategy / Data Spaces** — 個人データだけでなく、産業・公共領域のデータ共有を含む政策的な全体像を掴む。
5. **MyData** — 人間中心性、自己決定、仲介・ガバナンスの観点を加える。

- [IPA「データスペースの推進」](https://www.ipa.go.jp/digital/data/data-space.html)
- [EU: Data Spaces — Discovering the building blocks](https://data.europa.eu/en/news-events/news/learn-about-key-highlights-webinar-data-spaces-discovering-building-blocks)
- [DSSC Insight Series: Governance for Data Spaces](https://living-in.eu/knowledge-base/dssc-insight-series-governance-data-spaces)
- [Inrupt: What is ESS?](https://www.inrupt.com/videos/what-is-ess)
- [European data spaces: Scientific insights into data sharing and utilisation at scale](https://op.europa.eu/en/publication-detail/-/publication/dcac6aee-0e7a-11ee-b12e-01aa75ed71a1)
- [Engineering personal data protection in EU data spaces](https://op.europa.eu/en/publication-detail/-/publication/6a92f1fc-c4af-11ee-95d9-01aa75ed71a1/language-en)

## 9. 結論

Proton は、今すぐ利用できる「プライバシー重視のサービス群」によって中央集権的なデータ収集の代替を作る。Solid / Inrupt は、利用者・組織のデータをアプリから切り離し、Pod / Wallet と同意・相互運用性を通じて Web のデータ構造自体を変えようとする。EU の Data Spaces は、これを個人向け技術に限らず、産業・行政・公共分野に拡張するための制度・ガバナンス・市場形成の取り組みであり、MyData はその全体を「人がデータ利用を実効的に決められるか」という規範から照らす。

```text
Proton
  └─ 信頼できる代替サービスを作る

Solid / Inrupt
  └─ アプリとデータの関係を作り替える

EU Data Spaces
  └─ 分野横断で安全なデータ共有を成立させる制度・市場・ガバナンスを作る

MyData
  └─ そのすべてを人間中心・自己決定の観点で評価し、実装へつなぐ
```

各取り組みの難所は保存技術だけではない。意味の通じるデータ形式、本人にとって理解可能な同意、組織間の責任分担、競争と相互運用性のバランスを継続的に設計・運用できるかにある。
