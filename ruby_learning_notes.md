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
