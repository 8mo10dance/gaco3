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

## 文字列の基本操作

### 文字列の作成

```scheme
"hello"

(make-string 5 #\a)
;; => "aaaaa"

(string #\h #\e #\l #\l #\o)
;; => "hello"
```

文字と文字列は別物。

```scheme
#\a   ; 文字
"a"   ; 文字列
```

### 文字列の長さ

```scheme
(string-length "hello")
;; => 5
```

### 文字の取得

```scheme
(string-ref "hello" 1)
;; => #\e
```

インデックスは `0` 始まり。

### 部分文字列

```scheme
(substring "hello world" 0 5)
;; => "hello"

(substring "hello world" 6 11)
;; => "world"
```

範囲は `[start, end)`。

### 文字列の結合

```scheme
(string-append "hello" " " "world")
;; => "hello world"
```

### 文字列の比較

```scheme
(string=? "hello" "hello")
;; => #t

(string=? "hello" "Hello")
;; => #f

(string<? "abc" "def")
;; => #t
```

大文字・小文字を無視する場合：

```scheme
(string-ci=? "Hello" "HELLO")
;; => #t
```

### 文字列と文字リストの変換

#### String → List

```scheme
(string->list "hello")
;; => (#\h #\e #\l #\l #\o)
```

#### List → String

```scheme
(list->string '(#\h #\e #\l #\l #\o))
;; => "hello"
```

Scheme では文字列を文字のリストに変換して、`map`、`filter`、`fold` などで処理する方法も便利。

例：

```scheme
(list->string
  (map char-upcase
       (string->list "hello")))
;; => "HELLO"
```

## 標準入力

### `read`

```scheme
(define x (read))
```

`read` は入力を単なる文字列ではなく、**Scheme のデータとして読み込む**。

例えば、次の入力は数値 `123` として読まれる。

```text
123
```

次の入力は文字列ではなくシンボル `hello` として読まれる。

```text
hello
```

文字列として `read` させるには、入力自体に `"` が必要。

```text
"hello"
```

空白区切りの数値を読む用途では便利。

入力：

```text
10 20
```

コード：

```scheme
(define a (read))
(define b (read))

(+ a b)
;; => 30
```

### 1 行を文字列として読む

#### Guile

Guile では `read-line` を利用できる。環境によっては以下のモジュールを読み込む。

```scheme
(use-modules (ice-9 rdelim))
```

その後、次のように読む。

```scheme
(define line (read-line))
```

入力：

```text
hello world
```

結果：

```scheme
"hello world"
```

#### `(ice-9 rdelim)` とは

Guile が提供するモジュール。

```scheme
(use-modules (ice-9 rdelim))
```

これは Ruby で大雑把に考えると、次のようなものに近い。

```ruby
require "..."
```

`use-modules` は Scheme 共通の構文ではなく、**Guile のモジュールシステム**。

#### Gauche

Gauche では、`read-line` をそのまま利用できる。

```scheme
(define line (read-line))
```

## 文字列から数値への変換

`string->number` を使う。

```scheme
(string->number "123")
;; => 123

(string->number "-42")
;; => -42

(string->number "3.14")
;; => 3.14
```

## 等価性の比較

Scheme には用途の異なる比較手続きがある。

### `=`

数値として等しいかを比較する。

```scheme
(= 1 1)
;; => #t

(= 1 1.0)
;; => #t
```

数値専用なので、文字列やリストの比較には使わない。

### `eq?`

同一のオブジェクトかを比較する。

```scheme
(define a (list 1 2 3))
(define b a)

(eq? a b)
;; => #t
```

別々に生成したリストの場合：

```scheme
(define a (list 1 2 3))
(define b (list 1 2 3))

(eq? a b)
;; => #f
```

Ruby の `Object#equal?` に近い。

### `equal?`

構造・内容が等しいかを比較する。

```scheme
(equal? '(1 2 3) '(1 2 3))
;; => #t

(equal? '(1 (2 3)) '(1 (2 3)))
;; => #t
```

Ruby の `==` に近い。

ざっくり整理すると：

| Scheme | 意味 |
|---|---|
| `=` | 数値として等しい |
| `eq?` | 同一オブジェクト |
| `equal?` | 内容・構造が等しい |

---

## `any`

SRFI-1 の `any` は Ruby の `Enumerable#any?` に近い。

```scheme
(use-modules (srfi srfi-1))

(any even? '(1 3 4 5))
;; => #t
```

ただし `any` は単純に `#t` を返すとは限らず、最初に真となった述語の戻り値を返す。

```scheme
(any (lambda (x)
       (and (even? x) x))
     '(1 3 4 6))
;; => 4
```

すべて偽なら `#f`。

対になるものとして `every` がある。

```scheme
(every even? '(2 4 6))
;; => #t
```

Ruby との対応：

| Ruby | Scheme / SRFI-1 |
|---|---|
| `any?` | `any` |
| `all?` | `every` |

---

## 手続きをリストに入れる

Scheme では手続きも普通の値なので、リストに入れられる。

```scheme
(list + - * /)
```

そして取り出した手続きをそのまま呼び出せる。

```scheme
(any (lambda (op)
       (= (op 3 6) 9))
     (list + - * /))
;; => #t
```

---

## `'(...)` と `(list ...)` の違い

### `'(...)`

`'` は `quote` の省略形。

```scheme
'(+ - * /)
```

は、

```scheme
(quote (+ - * /))
```

と同じ。

`quote` の中身は評価されないため、これは `+`、`-`、`*`、`/` というシンボルを持つリストになる。

```scheme
(define x 10)

'(x 20)
;; => (x 20)
```

`x` は評価されない。

### `(list ...)`

`list` は通常の手続きなので、引数を評価してからリストを作る。

```scheme
(define x 10)

(list x 20)
;; => (10 20)
```

したがって、

```scheme
(list + - * /)
```

では `+` などが評価され、手続きのリストになる。

整理すると：

```text
(list a b c)
    ↓
a, b, c を評価
    ↓
評価結果のリストを作る


'(a b c)
    ↓
a, b, c を評価しない
    ↓
その構造自体をデータとして扱う
```

この「コードとデータが同じような構造をしている」という性質は Lisp / Scheme の重要な特徴。

---

## `for-each`

Ruby の `each` に相当する。

```scheme
(for-each
  (lambda (x)
    (display x)
    (newline))
  '(1 2 3))
```

出力：

```text
1
2
3
```

`map` との違いは、`map` が新しいリストを作るのに対し、`for-each` は主に副作用のために使うこと。

```scheme
(map (lambda (x) (* x 2))
     '(1 2 3))
;; => (2 4 6)

(for-each display
          '(1 2 3))
;; 123
```

Ruby との対応：

| Ruby | Scheme |
|---|---|
| `map` | `map` |
| `each` | `for-each` |
| `any?` | `any` |
| `all?` | `every` |

---

## `take` / `drop`

SRFI-1 に含まれる。

```scheme
(use-modules (srfi srfi-1))
```

### `drop`

左から n 個捨てる。

```scheme
(drop '(1 2 3 4 5) 2)
;; => (3 4 5)
```

### `drop-right`

右から n 個捨てる。

```scheme
(drop-right '(1 2 3 4 5) 2)
;; => (1 2 3)
```

### `take`

左から n 個取る。

```scheme
(take '(1 2 3 4 5) 2)
;; => (1 2)
```

### `take-right`

右から n 個取る。

```scheme
(take-right '(1 2 3 4 5) 2)
;; => (4 5)
```

まとめ：

| 手続き | 動作 |
|---|---|
| `take` | 左から n 個取る |
| `drop` | 左から n 個捨てる |
| `take-right` | 右から n 個取る |
| `drop-right` | 右から n 個捨てる |

---

## `let` / `let*` / `letrec`

### `let`

ローカルな変数を定義する。

```scheme
(let ((a 10)
      (b 20))
  (+ a b))
;; => 30
```

各変数の右辺からは、同じ `let` で新しく定義された変数は見えない。

### `let*`

上から順番に束縛する。

```scheme
(let* ((a 10)
       (b (+ a 20)))
  (+ a b))
;; => 40
```

後ろの定義から前の定義を参照できる。

### `letrec`

すべての束縛を相互に参照できる。

主にローカルな再帰関数に使う。

```scheme
(letrec ((fact
          (lambda (n)
            (if (= n 0)
                1
                (* n (fact (- n 1)))))))
  (fact 5))
;; => 120
```

相互再帰も可能。

```scheme
(letrec ((even?
          (lambda (n)
            (if (= n 0)
                #t
                (odd? (- n 1)))))
         (odd?
          (lambda (n)
            (if (= n 0)
                #f
                (even? (- n 1))))))
  (even? 10))
;; => #t
```

イメージ：

```text
let     横並び
let*    上から順番
letrec  お互いを参照可能
```

---

## named `let`

再帰的なループを書く場合は named `let` も便利。

```scheme
(let loop ((n 5)
           (acc 1))
  (if (= n 0)
      acc
      (loop (- n 1)
            (* acc n))))
;; => 120
```

ローカルな再帰関数を定義して即座に呼び出すような構造になっている。

---

## `string-split`

Guile では環境によって `string-split` が最初から見えているとは限らない。

利用する場合は対応するモジュールを読み込む。

```scheme
(use-modules (ice-9 string-fun))
```

例：

```scheme
(string-split "foo bar baz" #\space)
;; => ("foo" "bar" "baz")
```

区切りには文字列 `" "` ではなく character の `#\space` を渡す。

---

## `read-line` で数値を読む

`read-line` は文字列を返す。

例えば入力：

```text
3 6
```

に対して、

```scheme
(read-line)
;; => "3 6"
```

となる。

そのため、数値にするなら分割して `string->number` する必要がある。

```scheme
(map string->number
     (string-split (read-line) #\space))
;; => (3 6)
```

---

## `read` で数値を直接読む

競技プログラミングのように入力形式が決まっている場合は `read` が便利。

入力：

```text
3 6
```

に対して、

```scheme
(define a (read))
(define b (read))
```

とすると、

```scheme
a
;; => 3

b
;; => 6
```

となる。

`read` は Scheme の値として解釈するため `string->number` が不要。

また、空白と改行を入力値の区切りとして扱えるため、

```text
3 6
```

でも

```text
3
6
```

でも同じように、

```scheme
(read)
(read)
```

で読める。

---

## n 個の数値を `read` する

例えば、

```text
5
1 2 3 4 5
```

という入力を読む場合。

### `iota` + `map`

```scheme
(use-modules (srfi srfi-1))

(let* ((n (read))
       (as (map (lambda (_) (read))
                (iota n))))
  ...)
```

`iota n` は、

```scheme
(iota 5)
;; => (0 1 2 3 4)
```

を作る。

その各要素について `(read)` することで n 個読み込んでいる。

### 再帰で書く

```scheme
(define (read-n n)
  (if (= n 0)
      '()
      (cons (read)
            (read-n (- n 1)))))

(let* ((n (read))
       (as (read-n n)))
  ...)
```

こちらは「n 回 `read` する」という処理を直接表現している。

---

## 演算子を走査する例

ここまでの要素を組み合わせると、2つの数 `a`, `b` に対して `+`, `-`, `*`, `/` のどれかで 9 を作れるかは次のように書ける。

```scheme
(use-modules (srfi srfi-1))

(let ((a (read))
      (b (read)))
  (if (any (lambda (op)
             (= (op a b) 9))
           (list + - * /))
      (display "Nine")
      (display "Nein"))
  (newline))
```

`(list + - * /)` は手続きそのもののリスト。

`any` が各手続きを `op` として受け取り、

```scheme
(op a b)
```

として実行している。

なお `/` は `b = 0` の場合にはゼロ除算になるので、入力条件によっては別途考慮が必要。
