# Ruby 学習メモ

## Range

### `include?` は範囲を展開しない

``` ruby
(1..10).include?(10)
```

`1..10` が `[1,2,3,...,10]` に展開されるわけではない。

整数の `Range#include?` は範囲を利用して判定するので高速（平均 `O(1)`
に近い）。

### `cover?` との違い

``` ruby
("a".."z").include?("cc") # => false
("a".."z").cover?("cc")   # => true
```

-   `include?` は列挙した要素に含まれるか
-   `cover?` は範囲内かどうかだけを見る

### Float の Range

作ることはできる。

``` ruby
(1.0..2.0)
```

ただし

``` ruby
(1.0..2.0).each
```

はできない。

`Float` には `succ` がないため。

列挙したい場合は

``` ruby
(1.0..2.0).step(0.1)
```

を使う。

------------------------------------------------------------------------

## Enumerable

### each_with_index と each.with_index

-   普通は `each_with_index`
-   Enumerator をつなげたいなら `each.with_index`

### inject + with_index

``` ruby
array.each_with_index.inject(0) do |acc, (x, i)|
  acc + x * i
end
```

### drop_while

-   `drop_while` はある
-   `drop_while!` はない
-   `drop_while` は `O(n)`

### sort_by

``` ruby
users.sort_by { |u| u.age }
users.sort_by { |u| [u.age, u.name] }
users.sort_by { |u| -u.score }
```

### tally

``` ruby
arr.tally
```

出現回数を集計する。

------------------------------------------------------------------------

## Array

### 先頭追加

``` ruby
arr.unshift(x)
arr.prepend(x)
```

### tail

ない。

代わりに

``` ruby
arr[1..]
arr.drop(1)
```

### uniq

内部で Hash を使うため平均 `O(n)`。

``` ruby
arr.uniq.size
```

も `O(n)`。

### 配列 → Set

``` ruby
require "set"

arr.to_set
```

------------------------------------------------------------------------

## Hash

### カウンタ

``` ruby
Hash.new(0)
```

### 可変オブジェクト

``` ruby
Hash.new { |h, k| h[k] = [] }
Hash.new { |h, k| h[k] = Set.new }
```

------------------------------------------------------------------------

## Proc / Lambda

``` ruby
f = ->(x) { x * 2 }
f.call(3)
```

------------------------------------------------------------------------

## Float

### 絶対値

``` ruby
x.abs
```

### BigDecimal

``` ruby
require "bigdecimal/util"

"1.23".to_d
```

### Float::EPSILON

無限小ではなく、1.0 と次の Float の差。

### Double

約15〜16桁の精度。 `2^53` まで整数を正確に表現できる。

------------------------------------------------------------------------

## Deque

Ruby 標準にはない。

`shift` / `unshift` は `O(n)`。

### リングバッファ

-   head と tail を動かす
-   push は「書いてから tail を進める」
-   unshift は「head を戻してから書く」
-   `head == tail` 問題を避けるため `size` を持つ

------------------------------------------------------------------------

## その他

### トップレベルのインスタンス変数

``` ruby
@foo = 1
```

### 正規表現

``` ruby
/^[abc]/
```

### 最後のコード

最頻出文字（複数可）をすべて削除して出力する。

------------------------------------------------------------------------

## 数学ライブラリの設計

### Struct

`Struct` は「データを持つだけ」のオブジェクトを簡潔に定義するための仕組み。

``` ruby
Point = Struct.new(:x, :y)
```

向いている用途:

-   値オブジェクト
-   エッジ (`Edge`)
-   座標 (`Point`)
-   小さなDTO

`Vector` や `Matrix` のように、

-   不変条件を持つ
-   振る舞いが多い
-   内部表現を隠したい

という場合は普通の `class` の方が向いている。

### Vector / Matrix の設計

おすすめの方針は

-   `Vector` は一次元の要素列
-   `Matrix` は行ベクトルの集まり
-   イミュータブル
-   演算前に前提条件をチェック
-   `Vector < Array` のような継承はしない

#### 演算

``` ruby
v + w
v - w
v.dot(w)

m + n
m * v
m * n
```

`vector * vector` は意味が複数あるので、

``` ruby
v.dot(w)
v.hadamard(w)
v.outer(w)
```

のように名前を分ける方が分かりやすい。

### Enumerable

`Enumerable` は抽象クラスではなく **Module**。

``` ruby
class Vector
  include Enumerable

  def each(&block)
    ...
  end
end
```

#### include する条件

ほぼ

``` ruby
def each
  ...
end
```

を実装するだけ。

すると

-   `map`
-   `select`
-   `find`
-   `sum`
-   `count`

などが全部使える。

これは

> 「順番に要素を見せてくれれば残りは全部実装する」

という設計。

#### each のRuby流

``` ruby
def each
  return enum_for(__method__) unless block_given?

  ...
end
```

ブロックが無ければ `Enumerator` を返す。

#### Enumerable は型を保存しない

``` ruby
v.map { |x| x * 2 }
```

は

``` ruby
Array
```

を返す。

`Vector` にしたいなら

``` ruby
def map(&block)
  Vector.new(super)
end
```

のようにオーバーライドする。

同様に

-   `select`
-   `reject`
-   `filter`

なども `Array` を返す。

#### == は Enumerable には無い

`Enumerable` は `==` を定義しない。

理由はコレクションによって意味が違うから。

-   Array は順番を見る
-   Set は順番を見ない
-   Hash はキーと値を見る

`Vector` は自分で

``` ruby
def ==(other)
  ...
end
```

を書く。

### Comparable

`Comparable` は

``` ruby
include Comparable

def <=>(other)
  ...
end
```

だけ実装すると

-   `<`
-   `<=`
-   `>`
-   `>=`
-   `between?`

などを提供する。

`Enumerable` と対称的な設計になっている。

### 継承と Module

判断基準は次の通り。

#### 継承

"is-a"

``` text
Dog is Animal
```

#### Module

"can-do"

``` text
Tree can enumerate
Vector can enumerate
```

状態を共有するかどうかも一つの判断材料だが、本質的には

-   型の関係
-   能力の追加

の違い。

この考え方は Haskell の type class にかなり近い。

例えば

-   `Enumerable` ≈ `Foldable`
-   `Comparable` ≈ `Ord`

という感覚で理解できる。
