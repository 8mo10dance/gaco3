# OCaml 学習メモ

## 文字列の分割

### `String.split_on_char`

``` ocaml
let xs =
  read_line ()
  |> String.split_on_char ' '
```

-   戻り値は `string list`
-   区切り文字は `char` のみ
-   空文字列で区切ることはできない

### 文字単位に分割

``` ocaml
"abc"
|> String.to_seq
|> List.of_seq
```

## `Seq`

### foreach

``` ocaml
Seq.iter print_endline seq
```

### パターンマッチ

``` ocaml
match seq () with
| Seq.Nil -> ...
| Seq.Cons (x, xs) -> ...
```

### 添字アクセス

`Seq` はランダムアクセス不可。

-   `Seq.drop` + `Seq.uncons`（新しい OCaml）
-   または再帰
-   何度もアクセスするなら `Array.of_seq` / `List.of_seq` に変換

## List / Array

### リストと配列のパターン

リスト

``` ocaml
x :: xs
```

配列

``` ocaml
[|x; y|]
```

配列には `head :: tail` に相当するパターンはない。

### 反転

``` ocaml
List.rev
```

### インデックス付き map

``` ocaml
List.mapi (fun i x -> ...)
```

### 存在判定

``` ocaml
List.exists p xs
```

逆の条件は

``` ocaml
List.for_all (fun x -> not (p x)) xs
```

### ソート

``` ocaml
List.sort compare xs
```

`List.sort_by` は標準ライブラリにはない。

## String

### 添字アクセス

``` ocaml
s.[i]
```

配列は

``` ocaml
arr.(i)
```

### `String.to_list` はない

代わりに

``` ocaml
String.to_seq |> List.of_seq
```

逆変換は

``` ocaml
List.to_seq |> String.of_seq
```

## 標準入力

EOF まで読むなら

``` ocaml
let lines = In_channel.input_lines stdin
```

1行ずつ読むなら

``` ocaml
match In_channel.input_line stdin with
| None -> ...
| Some line -> ...
```

## `let*`

`let*` は構文糖衣。

``` ocaml
let* x = expr1 in
expr2
```

は

``` ocaml
(let*) expr1 (fun x -> expr2)
```

へ展開される。

`Option`、`Result`、`Lwt` などでよく使われる。

## リストの比較

辞書順で比較される。

``` ocaml
[1;2] < [1;3]
[1;2] < [1;2;0]
```

`compare` も利用可能。

## 転置行列

リストのリストなら

``` ocaml
let rec transpose = function
  | [] | [] :: _ -> []
  | rows ->
      List.map List.hd rows
      :: transpose (List.map List.tl rows)
```

## 競プロ向けのポイント

-   `String` は `s.[i]` で直接アクセスする
-   `Seq` は必要な場面だけ使う
-   EOF まで読むなら `In_channel.input_lines`
-   `List.mapi`、`List.exists`、`List.for_all`、`List.rev` は頻出
-   コンテナ変換は `Seq` 経由が基本
