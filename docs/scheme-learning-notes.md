# Scheme 学習メモ

## `fold` と `fold-right`

SRFI-1では、`fold` が左畳み込み、`fold-right` が右畳み込みです。

リストが `(a b c)`、初期値が `z` の場合、概念的には次の形になります。

```scheme
;; 左畳み込み
(fold f z '(a b c))
;; => (f c (f b (f a z)))

;; 右畳み込み
(fold-right f z '(a b c))
;; => (f a (f b (f c z)))
```

違うのは、演算を組み立てる方向です。

## 手続きの引数順

SRFI-1では、左右どちらの畳み込みでも手続きの引数は基本的に次の順です。

```scheme
(lambda (現在の要素 累積値) ...)
```

例えば、慣例的には次のように名前を付けられます。

```scheme
(lambda (element acc) ...)
```

「左畳み込み」という名前はラムダの引数順ではなく、リストを左から右へ処理することを表しています。

SRFI-1の `fold` は、おおむね次のループに相当します。

```scheme
(let loop ((xs list) (acc initial-value))
  (if (null? xs)
      acc
      (loop (cdr xs)
            (proc (car xs) acc))))
```

## 手続き名の違い

左畳み込みという概念はありますが、SRFI-1には `fold-left` という名前の手続きはありません。単に `fold` と呼ばれます。

```scheme
(fold       proc initial-value list) ; 左畳み込み
(fold-right proc initial-value list) ; 右畳み込み
```

名前はSchemeの規格や処理系によって異なります。

| ライブラリ・処理系 | 左畳み込み | 右畳み込み |
| --- | --- | --- |
| SRFI-1 | `fold` | `fold-right` |
| R6RS | `fold-left` | `fold-right` |
| Racket | `foldl` | `foldr` |

## 要点

- SRFI-1では `fold` が左畳み込み、`fold-right` が右畳み込み。
- ラムダの引数は、どちらも基本的に `(現在の要素 累積値)`。
- 畳み込みの手続き名は、Schemeの規格や処理系によって異なる。

## Guile の `identity`

Guile には、引数をそのまま返す `identity` がある。

```scheme
(identity 42)
;; => 42

(identity '(1 2 3))
;; => (1 2 3)
```

概念的には次の定義と同じ。

```scheme
(define (identity x) x)
```

追加の `use-modules` なしで利用できる。

```scheme
(map identity '(1 2 3))
;; => (1 2 3)
```

## Guile で range 的なものを作る

Guile では `iota` で連番のリストを生成できる。

```scheme
(iota 5)
;; => (0 1 2 3 4)
```

開始値も指定できる。

```scheme
(iota 5 1)
;; => (1 2 3 4 5)
```

刻み幅も指定できる。

```scheme
(iota 5 10 2)
;; => (10 12 14 16 18)
```

形式は次の通り。

```scheme
(iota count [start [step]])
```

Ruby の `(1..5).to_a` に近いものは `(iota 5 1)` となる。ただし Ruby の `Range` のような「範囲を表すオブジェクト」ではなく、`iota` は連番のリストを生成する手続き。

## Guile のリストへのインデックスアクセス

リストには `list-ref` でインデックスアクセスできる。

```scheme
(list-ref '(a b c d) 2)
;; => c
```

インデックスは 0 始まり。

```scheme
(list-ref '(10 20 30) 0)
;; => 10
```

ただし Scheme のリストは基本的に連結リストなので、`list-ref` は **O(n)**。頻繁にランダムアクセスする場合は `vector` の方が適している。

```scheme
(define xs #(10 20 30))

(vector-ref xs 2)
;; => 30
```

`vector-ref` はランダムアクセスに向いており、基本的に **O(1)**。

### 使い分け

| やりたいこと | Guile |
| --- | --- |
| 連番を作る | `iota` |
| リストの n 番目を取得 | `list-ref` |
| Vector の n 番目を取得 | `vector-ref` |
| 恒等関数 | `identity` |
| 順番に処理する | `map`, `fold` など |

Scheme のリストは先頭から順番に処理するのが得意なので、`iota` でインデックスを生成して `list-ref` を繰り返すより、可能なら `map` や `fold` で直接走査した方が自然で効率もよい。

## Guile の `use-modules` 構文の読み方

たとえば、次のように書く。

```scheme
(use-modules (srfi srfi-1))
```

Scheme の構文として見ると、まず一番外側は普通の S 式である。

```text
(use-modules ...)
```

つまり、`use-modules` という構文に引数を渡している。その中の `(srfi srfi-1)` は関数呼び出しではなく、**モジュール名を表す構文**である。

したがって全体としては、`(srfi srfi-1)` という名前のモジュールを現在のモジュールに取り込む、という意味になる。

### `(srfi srfi-1)` は何なのか

Guile のモジュール名は、このような**シンボルのリスト**で表現する。

```scheme
(ice-9 match)
(srfi srfi-1)
(system base compile)
```

概念的には、次のような階層名だと考えるとわかりやすい。

```text
ice-9 / match
srfi / srfi-1
system / base / compile
```

たとえば、次の式は `ice-9` の `match` モジュールを使う、と読める。

```scheme
(use-modules (ice-9 match))
```

### 重要な点: 普通の関数呼び出しではない

通常の Scheme の評価規則で `(srfi srfi-1)` を評価すると、`srfi` という手続きを `srfi-1` に適用する、という意味になってしまう。

しかし、`use-modules` は手続きではなく**特殊な構文（syntax）**である。そのため、引数を普通の式として評価しない。

```text
use-modules
    ↓
(srfi srfi-1) を「式」ではなく「モジュール名」として解釈する
```

これは `define` と似ている。

```scheme
(define x 10)
```

この場合も `x` は評価されず、「これから定義する変数名」として解釈される。同じように、**S 式の意味は先頭にある構文によって変わりうる**。

### まとめ

`use-modules` は、次のような独自の文法を持つ。

```scheme
(use-modules <module-name> ...)
```

ここでの `<module-name>` が `(srfi srfi-1)` という形をしている、と理解するとわかりやすい。
