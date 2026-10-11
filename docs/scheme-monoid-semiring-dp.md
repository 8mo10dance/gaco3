# Schemeで学ぶモノイド・括弧列・半環・DP

このノートでは、Scheme のサンプルコードを使って、モノイド、括弧列の要約、準同型、半環、動的計画法（DP）の関係を整理する。

## 1. モノイドの表現

モノイドは、集合、結合的な二項演算、単位元の組である。結合律により括弧の付け方を変更できるが、要素の順序を交換できるとは限らない。

モノイドを SRFI-9 のレコードで表す。`empty` は単位元、`append` は二項演算を保持する。
```scheme
(use-modules (srfi srfi-9))

(define-record-type <monoid>
  (make-monoid empty append)
  monoid?
  (empty monoid-empty)
  (append monoid-append))
```

コンストラクタは、**単位元、演算**の順になっている。

```scheme
(define add-monoid (make-monoid 0 +))
(define mul-monoid (make-monoid 1 *))


```

この引数順に合わせて、以下の例も記述する。

`monoid-pow` は同じ要素を繰り返し結合する処理である。一方、`monoid-fold` は任意の列を単位元から順に結合する処理として定義できる。


```scheme
(define (monoid-fold monoid xs)
  (let ((combine (monoid-append monoid)))
    (let loop ((acc (monoid-empty monoid)) (rest xs))
      (if (null? rest)
          acc
          (loop (combine acc (car rest)) (cdr rest))))))

(monoid-fold add-monoid '(2 3 4)) ; => 9
(monoid-fold mul-monoid '())      ; => 1
```

`combine` に累積値を左側、次の要素を右側として渡すことで、列の順序を保つ。

## 2. 高速化と計算結果の再利用

繰り返し二乗法は、指数が偶数なら底を二乗して指数を半分にし、奇数なら累積値に底を結合する。
```scheme
(define (monoid-pow monoid base n)
  (define (iter acc base i)
    (cond ((<= i 0) acc)
          ((even? i)
           (iter acc
                 ((monoid-append monoid) base base)
                 (/ i 2)))
          (else
            (iter ((monoid-append monoid) acc base)
                  base
                  (- i 1)))))
  (iter (monoid-empty monoid) base n))
```

この関数の入力 `n` は非負整数とする。

```scheme
(monoid-pow add-monoid 2 10) ; => 20（2を10回加える）
(monoid-pow mul-monoid 2 10) ; => 1024（2を10回掛ける）
```

サンプルの `monoid-pow` は繰り返し二乗法を使い、同じ要素を繰り返し結合する演算回数を減らしている。一方、行列積は結果をリストとして実体化し、要素を参照するたびに積を計算し直すことを避けている。

**繰り返し二乗法で演算回数を減らすことと、計算結果を保存して再利用することは別の工夫**である。

`monoid-pow` は非負整数の指数に対し、モノイド演算を O(log n) 回行う。ただし整数の桁数が増える場合まで含めて、実時間が O(log n) になるわけではない。

## 3. 括弧列の要約と準同型

1種類の括弧について、列を次の2値で要約すると、部分列の結果を結合できる。

- `b`：開き括弧を +1、閉じ括弧を −1 とした合計
- `m`：空の接頭辞も含む、接頭辞の合計の最小値

左側の要約 `(b1, m1)` と右側の要約 `(b2, m2)` の結合は次のとおり。

```text
(b1, m1) ⋄ (b2, m2)
  = (b1 + b2, min(m1, b1 + m2))
```

単位元は `(0, 0)`。文字の要約は `(` が `(1, 0)`、`)` が `(-1, -1)` になる。

| 括弧列 | 要約 | 判定 |
|---|---|---|
| 空列 | `(0, 0)` | 正しい |
| `()` | `(0, 0)` | 正しい |
| `)(` | `(0, -1)` | 不正 |
| `(()` | `(1, 0)` | 不正 |

正しい括弧列の条件は **`b = 0` かつ `m >= 0`**。合計だけでは `()` と `)(` を区別できないが、最小値を加えると判定できる。

列の要約を `h` とすると、次が成立する。

```text
h(xy) = h(x) ⋄ h(y)
h(空列) = (0, 0)
```

これがモノイド準同型である。「連結してから要約する」と「別々に要約してから結合する」が一致するため、分割処理や区間の集約ができる。

同じモノイド API を使った括弧列の例は、次のように書ける。
```scheme
(define (combine-summary left right)
  (let ((b1 (car left)) (m1 (cadr left))
        (b2 (car right)) (m2 (cadr right)))
    (list (+ b1 b2) (min m1 (+ b1 m2)))))

(define bracket-monoid
  (make-monoid '(0 0) combine-summary))

(define (char-summary ch)
  (cond ((char=? ch #\() '(1 0))
        ((char=? ch #\)) '(-1 -1))
        (else (error "括弧以外の文字" ch))))

(define (summarize text)
  (monoid-fold bracket-monoid
               (map char-summary (string->list text))))

(define (balanced? text)
  (let ((summary (summarize text)))
    (and (= (car summary) 0)
         (>= (cadr summary) 0))))

(summarize "()") ; => (0 0)
(summarize ")(") ; => (0 -1)
(balanced? "(())") ; => #t
(balanced? ")(")   ; => #f

(equal? (summarize "(())")
        (combine-summary (summarize "((") (summarize "))")))
; => #t
```
ただし、異なる種類の括弧の対応まで検査するには、この2値だけでは情報が足りない。

## 4. 半環の設計

半環は「加法モノイドと乗法モノイドの組」として表現できる。
```scheme
(define-record-type <semiring>
  (make-semiring add-monoid mul-monoid)
  semiring?
  (add-monoid semiring-add-monoid)
  (mul-monoid semiring-mul-monoid))
```


```scheme
(define natural-semiring
  (make-semiring add-monoid mul-monoid))
```

ただし、2つのモノイドを組み合わせるだけで半環になるわけではない。半環として扱うには、次の条件が必要になる。

- 2つの演算が同じ台集合を扱うこと
- 加法モノイドが可換であること
- 乗法が加法に対して左右の分配法則を満たすこと
- 加法の単位元が乗法の吸収元であること

自然数半環の台集合は、0を含む非負整数である。Scheme の `+` と `*` はより広い数値も扱えるため、入力の範囲は別途定める。

| 役割 | 自然数半環 | min-plus 半環 |
|---|---|---|
| 加法 | `+` | `min` |
| 乗法 | `*` | `+` |
| 零元 | `0` | `+inf.0` |
| 乗法単位元 | `1` | `0` |

半環から加法・乗法のモノイドを取り出すと、それぞれの演算と単位元を利用できる。

```scheme
(define add
  (monoid-append (semiring-add-monoid natural-semiring)))
(define mul
  (monoid-append (semiring-mul-monoid natural-semiring)))
(define zero
  (monoid-empty (semiring-add-monoid natural-semiring)))
(define one
  (monoid-empty (semiring-mul-monoid natural-semiring)))
```

## 5. 半環と DP の対応

サンプルの `count-paths` は次の式を評価する。
```scheme
(define (count-paths s ab bd ac cd)
  (let ((add (monoid-append (semiring-add-monoid s)))
        (mul (monoid-append (semiring-mul-monoid s))))
    (add
      (mul ab bd)
      (mul ac cd))))

(define min-plus-semiring
  (make-semiring
    (make-monoid +inf.0 min)
    (make-monoid 0 +)))


(count-paths natural-semiring 2 3 1 4) ; => 10
(count-paths min-plus-semiring 2 3 1 4) ; => 5
```


```text
(ab ⊗ bd) ⊕ (ac ⊗ cd)
```

自然数半環では経路数、min-plus 半環では最短距離になる。

```text
自然数：2 × 3 + 1 × 4 = 10
min-plus：min(2 + 3, 1 + 4) = 5
```

このサンプルは、固定されたダイヤ形の経路を評価する。任意のグラフを受け取る DP にするには、状態と遷移を扱う処理を追加する。

汎用 DAG の DP に進めるなら、次の漸化式をトポロジカル順に評価し、各頂点の結果を保存する。

```text
dp[v] = ⊕ { dp[u] ⊗ w(u, v) | u → v }
```

半環が担当するのは候補の接続・集約であり、グラフの構築、評価順、結果の保存は別途必要になる。

フィボナッチの行列累乗も通常の DP と同じ漸化式を扱うが、実装方式は表を順に埋める方法ではなく、繰り返される遷移をまとめて累乗する方法である。

行列の API を使うと、遷移の累乗を次のように表せる。
```scheme
(use-modules (matrix))

(define (matrix-monoid size)
  (make-monoid (unit-matrix size)
               compose-matrix))

(define (fib n)
  (let ((fib-matrix (monoid-pow (matrix-monoid 2)
                                (list->matrix
                                  '((0 1) (1 1)))
                                n)))
    (matrix-ref fib-matrix 0 1)))


(fib 10) ; => 55
```

行列 `((0 1) (1 1))` は、列ベクトル `(F_n, F_{n+1})` を `(F_{n+1}, F_{n+2})` に移す。

会話で扱った「半環で表現しにくい DP」も、この境界から理解できる。LIS は増加関係の DAG を作れば経路評価にできるが、比較条件とグラフの構築は半環の外側にある。行列連鎖積などの区間 DP は、2つの部分解の結合と分割点の列挙が必要で、単純な経路 DP とは評価構造が異なる。

大切なのは「半環で表せるか」だけでなく、**選んだ要素が計算を続けるための情報を十分に持ち、自然な計算量で扱えるか**である。括弧列で合計に最小値を追加したことも、同じ考え方に当たる。

## 関連ドキュメント

- [モノイドによる繰り返しの抽象化](./monoid-repetition-abstraction.md) — 二分累乗、関数合成、行列による状態遷移
- [Scheme 学習メモ](./scheme-learning-notes.md) — Scheme の構文、SRFI、末尾再帰、コレクション操作
- [隣接行列とグラフ探索](./graph-matrix-and-search.md) — 行列累乗による到達可能性とグラフ探索
