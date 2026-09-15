# データベース基礎まとめ

## 1. 3層スキーマモデル

3層スキーマモデルは、データベースを3つの異なる視点から記述するモデルである。

```text
                 概念スキーマ
                /            \
               /              \
        外部スキーマ        内部スキーマ
        利用者への表現      物理的な表現
```

### 外部スキーマ

特定のユーザーやアプリケーションから見えるデータベースの姿。

同じデータベースに対して複数の外部スキーマが存在できる。

### 概念スキーマ

データベース全体の論理的な構造。

- どのようなデータが存在するか
- 属性は何か
- データ同士がどのような関係を持つか
- どのような制約があるか

などを表す。

### 内部スキーマ

データを物理的にどのように保存するかを表す。

- ファイル配置
- ページ構造
- レコード配置
- B+Treeインデックス
- パーティション
- 圧縮方式

など。

### データ独立性

3層を分離する大きな目的は、ある層の変更を他の層へ波及させにくくすることである。

```text
外部スキーマ
     ↕
外部・概念マッピング
     ↕
概念スキーマ
     ↕
概念・内部マッピング
     ↕
内部スキーマ
```

#### 論理的データ独立性

概念スキーマを変更しても、外部スキーマへの影響を抑えられる性質。

#### 物理的データ独立性

内部スキーマを変更しても、概念スキーマへ影響させない性質。

---

## 2. データベースの正規化

正規化とは、データの依存関係を整理して、同じ事実が複数箇所に重複して保存されることを減らすための設計手法である。

### 正規化の目的

例えば、

```text
注文ID | 顧客ID | 顧客名
-------+--------+-------
1      | 10     | 田中
2      | 10     | 田中
3      | 10     | 田中
```

では、

```text
顧客ID 10 → 顧客名 田中
```

という同じ事実を何度も保存している。

正規化して、

```text
顧客

顧客ID | 顧客名
-------+-------
10     | 田中
```

```text
注文

注文ID | 顧客ID
-------+-------
1      | 10
2      | 10
3      | 10
```

とすれば、「顧客10の名前」という事実の保存場所を一箇所にできる。

正規化によって主に、

- 更新異常
- 挿入異常
- 削除異常

を防ぎやすくなる。

---

## 3. 関数従属

例えば、

```text
顧客ID → 顧客名
```

とは、

> 顧客IDが決まれば顧客名が一意に決まる

という意味である。

正規化では、

> この属性は本当は何によって決まっているのか？

を調べ、その依存関係に応じて事実を適切なテーブルへ配置する。

---

## 4. 第1〜第3正規形

### 第1正規形（1NF）

基本的には、一つの属性値を適切な単一値として扱える形にする。

### 第2正規形（2NF）

複合候補キーの一部分だけに依存する属性を分離する。

```text
注文ID → 注文日
商品ID → 商品名
```

のように、複合キー全体ではなく一部分だけに依存している状態を部分関数従属という。

### 第3正規形（3NF）

キー以外の属性を経由して別の属性が決まるような依存を整理する。

```text
社員ID → 部署ID → 部署名
```

なら、

```text
社員
社員ID → 部署ID

部署
部署ID → 部署名
```

と分割する。

---

## 5. 正規化を一般化して考える

正規化そのものは関係モデルの理論だが、その背後には、

> 同じ事実を複数箇所に保持すると、それらの同期が必要になり、整合性が壊れる可能性が生まれる

という一般的な問題がある。

これはSingle Source of Truthの考え方に近い。

> 独立した状態として保持する情報を最小限にし、導出できる情報はそこから導出する

という一般的な設計原則として考えることもできる。

逆に性能などを理由として意図的に情報を重複させるのが非正規化である。

```text
正規化
  → 重複が少ない
  → 整合性を保ちやすい

非正規化
  → 重複が増える
  → 読み取りなどを高速化できる
  → 整合性維持が難しくなる
```

---

## 6. トランザクション

正規化が、

> データ構造を工夫して整合性を壊れにくくする

ものだとすれば、トランザクションは、

> 複数の操作を行う途中で整合性が壊れないようにする

ための仕組みである。

```sql
BEGIN;

UPDATE accounts
SET balance = balance - 1000
WHERE id = 'A';

UPDATE accounts
SET balance = balance + 1000
WHERE id = 'B';

COMMIT;
```

途中で失敗した場合は `ROLLBACK` する。

---

## 7. ACID

ACIDはトランザクションが持つべき4つの性質である。

```text
Transaction
   │
   ├── Atomicity
   ├── Consistency
   ├── Isolation
   └── Durability
```

### Atomicity：原子性

> 全部成功するか、全部失敗するか

主にUndo logやRollbackなどによって実現される。

### Consistency：一貫性

> トランザクションの前後で、DBが定める整合性が維持される

DB制約、正しいアプリケーションロジック、ACIDの他の性質などによって成立する。

### Isolation：独立性

複数のトランザクションを並行実行しても、無秩序に干渉しないようにする性質。

主に、

- Lock
- MVCC

などによって実現される。

### Durability：永続性

> COMMITされた変更は、障害が起きても失われない

主にRedo log、WAL、永続ストレージなどによって実現される。

---

## 8. 回復処理

回復処理とは、

> 障害によって中途半端になったDBを正しい状態へ戻す処理

である。

基本的な判断は、

```text
未COMMIT
    ↓
変更を消したい

COMMIT済み
    ↓
変更を残したい
```

となる。

### UNDO

未完了トランザクションの変更を取り消す。

```text
未COMMIT
   ↓
 UNDO
   ↓
Atomicity
```

### REDO

COMMIT済みだがデータファイルへ反映しきれていない変更を再適用する。

```text
COMMIT済み
   ↓
 REDO
   ↓
Durability
```

### WAL

Write-Ahead Logging。

> データ本体を変更する前に、必要なログを先に永続化する

という原則。

```text
変更
 ↓
ログを永続化
 ↓
データ本体を変更
```

### チェックポイント

回復時にログを最初からすべて調べなくてもよいよう、回復処理の基準点を作る。

### バックアップからの回復

DBそのものを失った場合は、

```text
Backup
   ↓
Restore
   ↓
その後のログを適用
   ↓
障害直前の状態
```

のように回復する。

---

## 9. 排他制御

複数のトランザクションを同時実行すると、互いの処理が干渉する可能性がある。

例えば、

```text
初期値: balance = 1000

Transaction A        Transaction B

READ → 1000
                     READ → 1000

+100
                     +200

WRITE 1100
                     WRITE 1200
```

本来は1300になるべきところが1200になってしまう。

これをLost Updateという。

このような問題を防ぐため、LockやMVCCによって並行実行を制御する。

---

## 10. ロック

代表的なロックには、

- Shared Lock（S Lock / 共有ロック）
- Exclusive Lock（X Lock / 排他ロック）

がある。

共有ロック同士は共存できる。

```text
READ × READ → OK
```

排他ロックが絡む場合は競合する。

```text
READ × WRITE → 競合
WRITE × WRITE → 競合
```

ロックには、

```text
Database
 ↓
Table
 ↓
Page
 ↓
Row
```

などの粒度がある。

粗いロックは管理しやすいが競合しやすく、細かいロックは並行性能を高めやすい代わりに管理が複雑になる。

---

## 11. Dirty Read

まだCOMMITされていない変更を、別のトランザクションが読んでしまう現象。

```text
Transaction A        Transaction B

1000 → 0

                     READ → 0

ROLLBACK

0 → 1000
```

Bは最終的には存在しなかった値を読んでしまっている。

---

## 12. Non-repeatable Read

同じトランザクション内で同じ行を2回読んだとき、値が変わってしまう現象。

```text
Transaction A          Transaction B

READ → 1000

                       UPDATE → 2000
                       COMMIT

READ → 2000
```

---

## 13. Phantom Read

同じ検索条件を実行したとき、結果に含まれる行の集合が変わる現象。

```sql
SELECT *
FROM users
WHERE age >= 20;
```

1回目：

```text
Alice 25
Bob   30
```

別トランザクションが、

```sql
INSERT INTO users(name, age)
VALUES ('Carol', 22);

COMMIT;
```

すると、2回目は、

```text
Alice 25
Bob   30
Carol 22
```

となる。

```text
Non-repeatable Read
    ↓
同じ行の値が変わる

Phantom Read
    ↓
同じ条件で得られる行集合が変わる
```

---

## 14. Isolation Level

Isolation Levelとは、

> 並行するトランザクション同士をどこまで隔離するか

を決めるものである。

SQL標準では代表的に4段階ある。

```text
弱い
 ↑
READ UNCOMMITTED
READ COMMITTED
REPEATABLE READ
SERIALIZABLE
 ↓
強い
```

典型的には、

| Isolation Level | Dirty Read | Non-repeatable Read | Phantom Read |
|---|---:|---:|---:|
| READ UNCOMMITTED | ○ | ○ | ○ |
| READ COMMITTED | × | ○ | ○ |
| REPEATABLE READ | × | × | ○ |
| SERIALIZABLE | × | × | × |

○は発生しうる、×は防止されることを表す。

ただしこれはSQL標準上の整理であり、実際のDBMSではMVCCや独自のロック方式などによって挙動が異なる場合がある。

### READ UNCOMMITTED

他のトランザクションの未COMMIT変更まで見える可能性がある。

Dirty Readが発生しうる。

### READ COMMITTED

COMMIT済みのデータだけを見る。

Dirty Readは防げるが、Non-repeatable Readは発生しうる。

### REPEATABLE READ

同一トランザクション内で、一貫したデータを読み続けられるようにする。

MVCCでは、

```text
Version 1: 1000 ← 古いTx
Version 2: 2000 ← 新しいTx
```

のように複数バージョンを保持することで実現できる。

### SERIALIZABLE

並行実行した結果を、何らかの順番で直列実行した場合と同等にする。

```text
実際

Tx A ──────────→
     Tx B ──────────→

意味的には

Tx A → Tx B

または

Tx B → Tx A
```

となる。

---

## 15. LockとMVCC

Lockの基本思想は、

> 競合するなら待たせる

こと。

```text
Tx A → 🔒 → 更新 → COMMIT → 🔓
             ↑
           Tx B待機
```

MVCCの基本思想は、

> 複数のバージョンを保持し、それぞれのトランザクションに適切な状態を見せる

こと。

```text
              Row
             /   \
            /     \
      Version 1  Version 2
         ↑          ↑
       Tx A       Tx B
```

MVCCによって特にREADとWRITEの競合を減らせる。

ただしWRITE同士の競合などは依然として存在するため、現代のRDBMSではLockとMVCCを併用することが多い。

---

## 16. MySQL / InnoDBのIsolation

MySQLのInnoDBはSQL標準の4つのIsolation Levelをサポートする。

```text
READ UNCOMMITTED
       ↓
READ COMMITTED
       ↓
REPEATABLE READ  ← デフォルト
       ↓
SERIALIZABLE
```

InnoDBのデフォルトは `REPEATABLE READ`。

通常のSELECTではMVCCによるconsistent readが利用される。

例えば、

```text
Tx A                       Tx B

SELECT x → 100

                           UPDATE x = 200
                           COMMIT

SELECT x → 100
```

のように、Tx Aは一貫したスナップショットを参照できる。

一方、

```sql
SELECT ... FOR UPDATE;
UPDATE ...;
DELETE ...;
```

などではロックも利用される。

InnoDBでは、

- MVCC
- 行ロック
- gap lock
- next-key lock

などを組み合わせてIsolationを実現している。

そのため、SQL標準の単純なIsolation Level表だけでは実際の挙動を完全には説明できない。

---

## 17. SQLiteのIsolation

SQLiteでは基本的にトランザクションはSerializableとして扱われる。

特徴的なのは、

> 同時に書き込めるwriterを1つに限定する

という設計である。

```text
Writer A ─────────→ COMMIT
                    Writer B ─────────→ COMMIT
                                        Writer C ─────→
```

つまり、複数writer間の複雑な競合を処理するよりも、書き込みを直列化することでSerializableな実行を実現する。

### WAL mode

WAL modeではreaderとwriterを並行実行できる。

```text
              Database

Reader A → 古いsnapshot

Writer B → WALへ新しい変更を書く
```

readerは一貫したスナップショットを読み続ける。

この意味ではSnapshot Isolationとして振る舞う。

SQLiteでは特殊な設定を除けば、未COMMITデータを他の接続から読むDirty Readは通常発生しない。

---

## 18. Cloudflare D1のIsolation

Cloudflare D1はSQLiteをベースとしているが、クラウド上の分散サービスなのでSQLiteそのものとは実行モデルが異なる。

1つのD1 databaseでは、クエリ処理が基本的に直列化される。

概念的には、

```text
Request A ─┐
Request B ─┼─→ D1 Database → 順番に処理
Request C ─┘
```

となる。

そのためMySQLのように、

> READ COMMITTEDかREPEATABLE READか

というIsolation Levelの選択を中心に考えるDBではない。

### Read Replication

D1ではGlobal Read Replicationによって読み取りをreplicaへ分散できる。

```text
                  Primary
                    │
                  WRITE
                    │
          ┌─────────┼─────────┐
          ↓         ↓         ↓
       Replica    Replica    Replica
```

replicaへの反映には時間差が存在するため、

> どのバージョンのDBを読んでいるか

という別の問題が生じる。

これは通常のTransaction Isolationとは異なり、分散システムのConsistency Modelの問題である。

### SessionsとSequential Consistency

D1ではSessions APIを使うことでSequential Consistencyを確保できる。

例えば、

```text
WRITE x = 100
    ↓
READ x
```

という順序で操作した場合、後のREADがWRITE以前の状態へ巻き戻らないようにする。

bookmarkを利用して、

```text
Primary

version 100
    │
    ↓
bookmark = 100


Replica

version 97
   ↓
まだ利用しない

version 104
   ↓
READ可能
```

のように、必要な状態までreplicaが追いついていることを確認できる。

---

## 19. MySQL / SQLite / D1の比較

### MySQL

```text
複数トランザクションを積極的に並行実行

Tx A ────────────→
     Tx B ────────────→
  Tx C ────────────→

          ↓

     MVCC + Lock

          ↓

Isolation Levelで
どこまで干渉を許すか選択
```

デフォルトは `REPEATABLE READ`。

### SQLite

```text
Writer A ─────→
               Writer B ─────→
                              Writer C ─────→

       writerを直列化

             ↓

        Serializable
```

複雑なwriter concurrencyを許すより、書き込みを直列化する方向の設計。

### Cloudflare D1

```text
             Primary
                │
              WRITE
                │
        ┌───────┼───────┐
        ↓       ↓       ↓
       R1      R2      R3

                ↓

        replica利用時には
        DBのversionが問題になる

                ↓

      Sessions / Bookmarks

                ↓

     Sequential Consistency
```

D1では、通常のTransaction Isolationに加えて、分散レプリカ間のConsistencyも考える必要がある。

---

## 20. Transaction Isolationと分散Consistency

ここは区別が重要。

### Transaction Isolation

MySQLなどで問題になる。

> 同じDB上で並行して実行されるトランザクション同士をどのように見せるか

という問題。

```text
Tx A ──────────→
    Tx B ──────────→

       ↓

Dirty Read?
Non-repeatable Read?
Phantom Read?
```

### 分散システムのConsistency

D1のRead Replicationなどで問題になる。

> 複数のコピーが存在するとき、どのバージョンのデータを観測するか

という問題。

```text
          Primary
          version 10
         /          \
        ↓            ↓
Replica A         Replica B
version 10        version 8
```

ここではIsolation Levelではなく、

- Sequential Consistency
- replica lag
- session
- bookmark

などが問題になる。

したがって、

```text
Isolation
    ↓
「同時に走るTransaction同士」の問題

Distributed Consistency
    ↓
「複数コピーのどれを観測するか」の問題
```

と分けて考えると理解しやすい。

---

## 21. 全体像

ここまでの内容は、すべて「状態の整合性をどう維持するか」という問題としてつながっている。

```text
                       データの整合性
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
      正規化            Transaction          Recovery
        │                   │                   │
  状態の重複を減らす        ACID           障害から回復する
                            │
                 ┌──────────┼──────────┐
                 │          │          │
                 A          I          D
                 │          │          │
               UNDO       Isolation   REDO/WAL
                            │
                     ┌──────┴──────┐
                     │             │
                    Lock          MVCC
                     │             │
                     └──────┬──────┘
                            │
                     Isolation Level
                            │
               ┌────────────┼────────────┐
               │            │            │
           Dirty Read   Non-repeatable  Phantom
                            Read          Read
```

さらに分散DBになると、別の軸が追加される。

```text
                    Database
                       │
              ┌────────┴────────┐
              │                 │
       Transaction内部       DBコピー間
              │                 │
         Isolation         Consistency
              │                 │
       Isolation Level     Replica / Session
                                │
                       Sequential Consistency
```

したがって、

- 正規化は「どの状態を保持するか」
- Transactionは「状態をどう安全に変更するか」
- Isolationは「並行する変更をどう制御するか」
- Recoveryは「障害後に状態をどう復元するか」
- Distributed Consistencyは「複数コピーの状態をどう観測させるか」

という形で整理できる。
