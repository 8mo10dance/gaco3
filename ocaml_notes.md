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

## List

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
