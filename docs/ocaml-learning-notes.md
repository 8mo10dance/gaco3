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

## Set

```ocaml
module IntSet = Set.Make(Int)

let s = IntSet.of_list xs
IntSet.cardinal s
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
