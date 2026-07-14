# へび問題から学んだ設計メモ

## 1. 方角は整数で表現する

方角を循環する整数として扱うと、回転が単なる足し算になる。

  方角     値
  ------ ----
  N         0
  E         1
  S         2
  W         3

反時計回りを正にするなら `N, W, S, E`
の順に並べてもよい。重要なのは一貫性。

## 2. 相対方向も整数

``` ruby
REL = {
  'F' => 0,
  'L' => 1,
  'B' => 2,
  'R' => 3
}
```

``` ruby
dir = (current + REL[action]) % 4
```

で絶対方向が求められる。

## 3. ベクトルを持つ

``` ruby
DELTA = [
  [0, -1],
  [1, 0],
  [0, 1],
  [-1, 0],
]
```

方向から移動量を取り出せる。

## 4. Point は値オブジェクト

``` ruby
Point = Struct.new(:x, :y) do
  def initialize(...)
    super
    freeze
  end

  def move(dx, dy)
    self.class.new(x + dx, y + dy)
  end
end
```

-   破壊的変更をしない
-   Set に入れても安全

## 5. Direction も値オブジェクト

``` ruby
class Direction
  DELTA = [
    [0, -1],
    [1, 0],
    [0, 1],
    [-1, 0],
  ].freeze

  def initialize(index = 0)
    @index = index
    freeze
  end

  def right
    self.class.new((@index + 1) % DELTA.size)
  end

  def delta
    DELTA[@index]
  end
end
```

## 6. 責務を分離する

-   Point: 座標
-   Direction: 向き・回転
-   Snake: 移動ルール・訪問済み管理

## 7. 不変オブジェクト

``` ruby
point = point.move(dx, dy)
direction = direction.right
```

どちらも新しい値を返す。

## 8. 学び

競プロでも、

-   座標
-   方角
-   移動
-   シミュレーション

を小さなオブジェクトとして分けると、ゲームやシミュレーションにも応用しやすい。

「方角は循環群」「座標は値オブジェクト」という考え方は、長く使える設計になる。
