# OCamlで標準入力を扱う方法

## 1. 1行読む

```ocaml
let line = read_line ()
``

EOFになると `End_of_file` 例外が発生する。

---

## 2. 全行を読みながら処理する

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

---

## 3. Seq.unfold を使って標準入力を Seq にする

```ocaml
let lines =
  Seq.unfold
    (fun ic ->
      In_channel.input_line ic
      |> Option.map (fun line -> (line, ic)))
    stdin
``

### イメージ

```text
stdin
↓
line1
line2
line3
...
```

`Seq.unfold` は状態 (`stdin`) から lazy sequence を生成する。

---

## 4. map / filter を使う

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

---

## 5. scan（累積状態）

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

---

## 6. Seq の内部構造

概念的には:

```ocaml
type 'a node =
  | Nil
  | Cons of 'a * 'a Seq.t
```

実際の Seq は

```ocaml
type 'a Seq.t = unit -> 'a node
```

に近い。

### List との対応

| List | Seq |
|------|------|
| `[]` | `Seq.Nil` |
| `x :: xs` | `Seq.Cons (x, xs)` |
| eager | lazy |

---

## 7. エラトステネスの篩

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

---

## 8. Reactive Programming 的な見方

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

---

## まとめ

- `read_line` は1行読む
- `Seq.unfold` で標準入力をストリーム化できる
- `map` / `filter` / `scan` を組み合わせて処理できる
- `Seq` は lazy な List と考えると理解しやすい
- `stdin → Seq → 変換 → 出力` は Reactive Programming 的な構造になる
