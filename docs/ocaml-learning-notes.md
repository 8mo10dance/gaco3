# OCaml 学習メモ

## レコード

```ocaml
type person = {
  name : string;
  age : int;
}

let alice = { name = "Alice"; age = 20 }

alice.name
alice.age
```

更新:

```ocaml
let older = { alice with age = alice.age + 1 }
```

可変:

```ocaml
type counter = {
  mutable count : int;
}
```

## 関数と変数

### 命名規則

関数名や変数名は小文字または `_` で始め、通常は `snake_case` を使う。

```ocaml
let find_user_by_id id users =
  (* ... *)
```

`bool` を返す関数には `is_`、`has_`、`can_` などを付けることが多い。

```ocaml
let is_even n = n mod 2 = 0
```

大文字で始まる名前は、主にモジュール名やコンストラクタに使われる。

### 定義の順番

OCaml は上から順に型検査するため、関数は基本的に使用箇所より前に定義する。

```ocaml
let increment x = x + 1
let result = increment 10
```

自分自身を呼び出す場合は `let rec` が必要。

```ocaml
let rec factorial n =
  if n = 0 then 1
  else n * factorial (n - 1)
```

JavaScript の関数宣言のような巻き上げはない。

### ローカル変数

式の中では `let ... in ...` でローカルな束縛を作る。

```ocaml
let distance x y =
  let squared = x *. x +. y *. y in
  sqrt squared
```

普通の `let` は再代入ではなく、新しい名前と値の束縛である。

```ocaml
let x = 10 in
let x = x + 1 in
x
(* 11 *)
```

### カリー化と部分適用

OCaml の複数引数関数は通常カリー化される。

```ocaml
let add x y = x + y
(* int -> int -> int *)
```

部分適用もできる。

```ocaml
let add10 = add 10
let result = add10 5
(* 15 *)
```

一方、タプルを受け取る関数は別の型になる。

```ocaml
let add_pair (x, y) = x + y
(* int * int -> int *)
```

### コメント

コメントは `(*` と `*)` で囲む。複数行やネストも可能。

```ocaml
(* 一行コメント *)

(*)
  複数行コメント
  (* ネストしたコメント *)
*)
```

## 数値

### 二乗

```ocaml
let square x = x * x
let squaref x = x *. x
```

### 累乗

```ocaml
2.0 ** 10.0
Float.pow 2.0 10.0
```

### 平方根

```ocaml
sqrt 9.0
Float.sqrt 9.0
```

`sqrt` の引数と結果は `float`。整数を渡す場合は `float_of_int` で変換する。

```ocaml
sqrt (float_of_int 9)
(* 3.0 *)
```

### 絶対値

```ocaml
abs (-5)
Float.abs (-3.5)
```

### 最大・最小

```ocaml
max a b
min a b

Float.max a b
Float.min a b
```

### float の精度

-   IEEE754 倍精度
-   有効数字は約15〜17桁
-   18桁以上は正確に表現できない
-   大きな整数は Int64.t や Zarith を使う

## String

### 文字列の分割

`String.split_on_char` の戻り値は `string list`。区切り文字には `char` を指定する。

```ocaml
let xs =
  read_line ()
  |> String.split_on_char ' '
```

文字単位に分割する場合:

```ocaml
"abc"
|> String.to_seq
|> List.of_seq
```

### 添字アクセスとリストへの変換

```ocaml
s.[i]
```

`String.to_list` はないため、`Seq` を経由する。

```ocaml
String.to_seq |> List.of_seq
List.to_seq |> String.of_seq
```

## List / Array

```ocaml
List.length xs
List.filter pred xs
List.map2 (fun x y -> x + y) xs ys
List.mapi (fun i x -> (i, x)) xs
```

空リスト:

```ocaml
[]
```

### パターン

リストは先頭要素と残りの要素に分解できる。

```ocaml
x :: xs
```

配列には `head :: tail` に相当するパターンはない。要素には `arr.(i)` でアクセスする。

```ocaml
[|x; y|]
```

### よく使う操作

```ocaml
List.rev xs
List.mapi (fun i x -> (i, x)) xs
List.exists p xs
List.for_all (fun x -> not (p x)) xs
List.sort compare xs
```

`List.sort_by` は標準ライブラリにはない。

### リストの比較

リストは辞書順で比較される。

```ocaml
[1; 2] < [1; 3]
[1; 2] < [1; 2; 0]
```

`compare` も利用できる。

### 転置行列

リストのリストを転置する例:

```ocaml
let rec transpose = function
  | [] | [] :: _ -> []
  | rows ->
      List.map List.hd rows
      :: transpose (List.map List.tl rows)
```

### range

OCaml の標準ライブラリには Python の `range` と同じ関数はないが、`List.init` で作れる。

```ocaml
let range from until =
  if until <= from then []
  else List.init (until - from) (fun i -> from + i)
```

```ocaml
range 0 10
(* [0; 1; 2; 3; 4; 5; 6; 7; 8; 9] *)
```

`until` は結果に含まれない。

### filter

`List.filter` は、条件を満たす要素だけを残す。

```ocaml
List.filter (fun x -> x mod 2 = 0) [0; 1; 2; 3; 4; 5]
(* [0; 2; 4] *)
```

型は次の通り。

```ocaml
List.filter : ('a -> bool) -> 'a list -> 'a list
```

### exists と for_all

Ruby の `any?` に相当するのが `List.exists`。

```ocaml
List.exists (fun x -> x mod 2 = 0) [1; 4; 5]
(* true *)
```

すべての要素が条件を満たすか調べる場合は `List.for_all` を使う。

```ocaml
List.for_all (fun x -> x mod 2 = 0) [2; 4; 6]
(* true *)
```

### fold

`List.fold_left` は、左から順にリストを一つの値へ畳み込む。

```ocaml
List.fold_left (fun acc x -> acc + x) 0 [1; 2; 3; 4]
(* 10 *)
```

短く書くと次のようになる。

```ocaml
List.fold_left (+) 0 [1; 2; 3; 4]
```

処理の形は次の通り。

```text
(((0 + 1) + 2) + 3) + 4
```

`List.fold_right` は右から畳み込む。

```ocaml
List.fold_right (fun x acc -> x :: acc) [1; 2; 3] []
(* [1; 2; 3] *)
```

`fold_left` と `fold_right` は引数の順番も異なる。

```ocaml
List.fold_left  f initial list
List.fold_right f list initial
```

### flatten と flat_map

一段のリストを平らにするには `List.flatten` または `List.concat` を使う。

```ocaml
List.flatten [[1; 2]; [3; 4]; [5]]
(* [1; 2; 3; 4; 5] *)
```

`flat_map` に相当するのは `List.concat_map`。

```ocaml
List.concat_map (fun x -> [x; x * 10]) [1; 2; 3]
(* [1; 10; 2; 20; 3; 30] *)
```

これは次と同じ意味になる。

```ocaml
List.flatten (List.map (fun x -> [x; x * 10]) [1; 2; 3])
```

## Set

```ocaml
module IntSet = Set.Make(Int)

let s = IntSet.of_list xs
IntSet.cardinal s
```

`IntSet.t` は抽象型なので、`utop` でそのまま評価しても中身は表示されない。

```ocaml
- : IntSet.t = <abstr>
```

確認するときは `IntSet.to_list` を使う。

```ocaml
let numbers = IntSet.of_list [3; 1; 2; 3]

IntSet.mem 2 numbers
(* true *)

IntSet.to_list numbers
(* [1; 2; 3] *)
```

### Set.Make が必要な理由

`Set` は内部で要素を順序付けるため、要素型だけでなく比較関数も必要になる。

```ocaml
module type OrderedType = sig
  type t
  val compare : t -> t -> int
end
```

`Int` モジュールは `type t = int` と `Int.compare` を提供するので、`Set.Make(Int)` に渡せる。

自作型では比較基準を明示できる。

```ocaml
type user = {
  id : int;
  name : string;
}

module UserSet = Set.Make(struct
  type t = user

  let compare a b =
    Int.compare a.id b.id
end)
```

ここでは `id` が同じユーザーは、集合上では同じ要素として扱われる。

OCaml にジェネリック関数がないわけではない。例えば `List.length` は任意の要素型に使える。

```ocaml
List.length : 'a list -> int
```

ただし標準 OCaml には、型に対応する比較処理を暗黙に探索する仕組みがない。そのため `Set` は、型と操作をまとめたモジュールを `Set.Make` に明示的に渡す設計になっている。

### Set の fold

`IntSet.fold` の引数順は次の通り。

```ocaml
IntSet.fold f set initial
```

パイプで集合を最後に渡したい場合はラッパーを用意できる。

```ocaml
let fold_set f initial set =
  IntSet.fold f set initial
```

```ocaml
numbers
|> fold_set (+) 0
```

### Set の flatten

`IntSet` には `flatten` はない。`IntSet.t list` を一つの集合にするなら `union` で畳み込む。

```ocaml
let flatten_set_list sets =
  List.fold_left IntSet.union IntSet.empty sets
```

ただし `IntSet.t` は整数の集合なので、`IntSet.t` 自体をその要素にはできない。変換しながら集合へまとめる場合は、直接 `fold` する方が自然。

```ocaml
let flat_map_set f set =
  IntSet.fold
    (fun x acc -> IntSet.union (f x) acc)
    set
    IntSet.empty
```

### Map

`Map` もキーの比較方法が必要なので、`Map.Make` で専用モジュールを作る。

```ocaml
module IntMap = Map.Make(Int)

let names =
  IntMap.empty
  |> IntMap.add 1 "one"
  |> IntMap.add 2 "two"
```

```ocaml
IntMap.find_opt 2 names
(* Some "two" *)

IntMap.bindings names
(* [(1, "one"); (2, "two")] *)
```

## cons

```ocaml
let cons x xs = x :: xs

[]
|> cons 3
|> cons 2
|> cons 1
```

## Printf

```ocaml
Printf.printf "%d\n" 42
Printf.printf "%s\n" "hello"
Printf.printf "%.2f\n" 3.14

Printf.sprintf "%d + %d = %d" 1 2 3
Printf.eprintf "error: %s\n" msg
```

## 標準入力

### 1行読む

```ocaml
let line = read_line ()
```

EOF になると `End_of_file` 例外が発生する。

`In_channel` を使う場合、全行は `input_lines`、1行ずつなら `input_line` で取得する。

```ocaml
let lines = In_channel.input_lines stdin

match In_channel.input_line stdin with
| None -> ...
| Some line -> ...
```

### 全行を読みながら処理する

```ocaml
let () =
  try
    while true do
      let line = read_line () in
      print_endline line
    done
  with
  | End_of_file -> ()
```

### Seq.unfold で標準入力を Seq にする

```ocaml
let lines =
  Seq.unfold
    (fun ic ->
      In_channel.input_line ic
      |> Option.map (fun line -> (line, ic)))
    stdin
```

イメージ:

```text
stdin
↓
line1
line2
line3
...
```

`Seq.unfold` は状態、ここでは `stdin` から lazy sequence を生成する。

### map / filter を使う

```ocaml
let () =
  Seq.unfold
    (fun ic ->
      In_channel.input_line ic
      |> Option.map (fun line -> (line, ic)))
    stdin
  |> Seq.map String.uppercase_ascii
  |> Seq.iter print_endline
```

### scan で累積状態を扱う

```ocaml
let scan f init seq =
  Seq.unfold
    (fun (state, seq) ->
      match seq () with
      | Seq.Nil -> None
      | Seq.Cons (x, rest) ->
          let state' = f state x in
          Some (state', (state', rest)))
    (init, seq)
```

累積和:

```ocaml
stdin_lines
|> Seq.map int_of_string
|> scan (+) 0
|> Seq.iter (Printf.printf "%d\n")
```

入力:

```text
1
2
3
4
```

出力:

```text
1
3
6
10
```

## Seq

### 走査とパターンマッチ

```ocaml
Seq.iter print_endline seq

match seq () with
| Seq.Nil -> ...
| Seq.Cons (x, xs) -> ...
```

`Seq` はランダムアクセスできない。`Seq.drop` と `Seq.uncons` を使うか、再帰で走査する。何度も添字アクセスする場合は `Array.of_seq` または `List.of_seq` で変換する。

### 内部構造

概念的には:

```ocaml
type 'a node =
  | Nil
  | Cons of 'a * 'a Seq.t
```

実際の `Seq` は次の形に近い。

```ocaml
type 'a Seq.t = unit -> 'a node
```

### List との対応

| List | Seq |
|------|------|
| `[]` | `Seq.Nil` |
| `x :: xs` | `Seq.Cons (x, xs)` |
| eager | lazy |

### エラトステネスの篩

```ocaml
let rec sieve seq () =
  match seq () with
  | Seq.Nil -> Seq.Nil
  | Seq.Cons (p, rest) ->
      Seq.Cons
        (p, sieve (Seq.filter (fun n -> n mod p <> 0) rest))

let primes =
  sieve (Seq.ints 2)
```

利用:

```ocaml
primes
|> Seq.take 20
|> List.of_seq
```

### Reactive Programming 的な見方

```text
stdin
↓ unfold
event stream
↓ map/filter
transformation
↓ scan
state evolution
↓ iter
side effect
```

この構造は FRP やストリーム処理の基本形に近い。

## `let*`

`let*` は構文糖衣で、次の式:

```ocaml
let* x = expr1 in
expr2
```

は次の形へ展開される。

```ocaml
(let*) expr1 (fun x -> expr2)
```

`Option`、`Result`、`Lwt` などでよく使われる。

## 競技プログラミング向けのポイント

- `String` は `s.[i]` で直接アクセスする
- `Seq` は必要な場面だけ使う
- EOF まで読むなら `In_channel.input_lines` を使う
- `List.mapi`、`List.exists`、`List.for_all`、`List.rev` は頻出
- コンテナ変換は `Seq` を経由できる

## Devbox

ビルドだけ:

```json
{
  "packages": [
    "ocaml",
    "dune"
  ]
}
```

REPL:

```json
{
  "packages": [
    "ocaml",
    "dune",
    "utop"
  ]
}
```

opam:

```bash
opam init --no-setup -y
```

## メモ

- Seq は lazy
- List は eager
- Set の要素数は `cardinal`
- List の長さは `List.length`
- `with_index` 相当は `List.mapi`
- `map2` は `fun x y -> ...` を受け取る
- `read_line` は1行読む
- `Seq.unfold` で標準入力をストリーム化できる
- `map` / `filter` / `scan` を組み合わせて処理できる
- `stdin → Seq → 変換 → 出力` は Reactive Programming 的な構造になる

## 約数と完全数

平方根以下の約数 `x` を見つけたら、対になる `n / x` も集合へ追加できる。

```ocaml
let fold_set f initial set =
  IntSet.fold f set initial

let divisors n =
  let upper = float_of_int n |> sqrt |> int_of_float in
  range 1 (upper + 1)
  |> IntSet.of_list
  |> IntSet.filter (fun x -> n mod x = 0)
  |> fold_set
       (fun x acc ->
         acc
         |> IntSet.add x
         |> IntSet.add (n / x))
       IntSet.empty
```

```ocaml
divisors 12 |> IntSet.to_list
(* [1; 2; 3; 4; 6; 12] *)
```

約数の合計と完全数判定は次のように書ける。

```ocaml
let sum set =
  IntSet.fold (+) set 0

let sum_of_divisors n =
  divisors n |> sum

let is_perfect_number n =
  n * 2 = sum_of_divisors n

let perfect_numbers upper =
  range 1 (upper + 1)
  |> List.filter is_perfect_number
```

```ocaml
perfect_numbers 10000
(* [6; 28; 496; 8128] *)
```

## リストを二つに分割する

リストのすべての分割位置を列挙する関数は次のように書ける。

```ocaml
let rec group2 lst =
  match lst with
  | [] -> [([], [])]
  | x :: xs ->
      ([], lst)
      :: (group2 xs
          |> List.map (fun (left, right) -> (x :: left, right)))
```

```ocaml
group2 [1; 2; 3]
(*
  [([], [1; 2; 3]);
   ([1], [2; 3]);
   ([1; 2], [3]);
   ([1; 2; 3], [])]
*)
```

ここで重要な構文は次の通り。

```ocaml
x :: xs       (* リストの先頭と残り *)
(left, right) (* ペア *)
```

再帰呼び出しを行うため、定義には `let rec` が必要になる。
