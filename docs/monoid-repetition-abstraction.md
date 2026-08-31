# モノイドによる繰り返しの抽象化

## モノイド

モノイドは、次の二つを持つ構造として表現できる。

- 単位元 `empty`
- 結合的な演算 `append`

```ocaml
type 'a monoid = {
  empty : 'a;
  append : 'a -> 'a -> 'a;
}
```

整数の加算と乗算は、それぞれ異なるモノイドになる。

```ocaml
let add_monoid = {
  empty = 0;
  append = (+);
}

let multiply_monoid = {
  empty = 1;
  append = ( * );
}
```

## モノイドの累乗

モノイドの要素を繰り返し合成する処理は一般化できる。

```ocaml
let monoid_pow monoid element n =
  if n < 0 then invalid_arg "monoid_pow: negative exponent"
  else
    let rec iter acc base exponent =
      if exponent = 0 then acc
      else if exponent mod 2 = 1 then
        iter
          (monoid.append acc base)
          (monoid.append base base)
          (exponent / 2)
      else
        iter
          acc
          (monoid.append base base)
          (exponent / 2)
    in
    iter monoid.empty element n
```

これは二分累乗なので、`append` の回数は `O(log n)` になる。

```ocaml
monoid_pow add_monoid 2 5
(* 10 *)

monoid_pow multiply_monoid 2 5
(* 32 *)
```

## 関数合成をモノイドとして扱う

繰り返し処理と具体的な処理内容を分離したい場合、値の加算や乗算ではなく、`'a -> 'a` という自己関数をモノイドの要素として扱える。

関数合成の単位元は恒等関数 `Fun.id`、演算は関数合成になる。

```ocaml
let compose f g x =
  f (g x)

let endo_monoid = {
  empty = Fun.id;
  append = compose;
}
```

このような `'a -> 'a` の関数は endomorphism（自己写像）と呼ばれ、その関数合成はモノイドを作る。

```ocaml
let repeat f n =
  monoid_pow endo_monoid f n
```

`repeat` の戻り値も関数になる。

```ocaml
let add2 = fun x -> x + 2
let double = fun x -> x * 2

repeat add2 5 0
(* 10 *)

repeat double 5 1
(* 32 *)
```

部分適用を使えば次のようにも書ける。

```ocaml
let mul2 n =
  repeat ((+) 2) n 0

let pow2 n =
  repeat (( * ) 2) n 1
```

役割は次のように分離される。

```text
(fun x -> x + 2)  1回分の処理
repeat             処理をn回合成する仕組み
0                  合成した関数へ渡す初期状態
```

`repeat` は具体的な加算や乗算を知らず、関数の合成方法だけを知っている。

## 行列モノイドとフィボナッチ数列

### 行列積のモノイド

正方行列は、行列積を演算、単位行列を単位元とするモノイドになる。

```ocaml
let identity_matrix size =
  List.init size (fun i ->
    List.init size (fun j ->
      if i = j then 1 else 0))

let transpose matrix =
  match matrix with
  | [] -> []
  | row :: _ ->
      List.init (List.length row) (fun column ->
        List.map (fun row -> List.nth row column) matrix)

let dot xs ys =
  List.map2 ( * ) xs ys
  |> List.fold_left (+) 0

let multiply_matrix a b =
  let columns = transpose b in
  List.map
    (fun row -> List.map (dot row) columns)
    a

let matrix_monoid size = {
  empty = identity_matrix size;
  append = multiply_matrix;
}
```

このリスト表現では行列の形が型に含まれないため、不正なサイズでは `List.map2` などが例外を送出する。学習用としては簡潔だが、本格的に使う場合は行列型とサイズ検証を用意した方がよい。

### フィボナッチ数列の状態

フィボナッチ数列の状態を次のベクトルで表す。

```text
state_n = [F_(n+1); F_n]
```

初期状態は次の通り。

```text
state_0 = [1; 0]
```

遷移行列は次になる。

```text
      [1  1]
A  =  [1  0]
```

この行列を状態へ掛けると、一つ次の状態が得られる。

```text
A [F_(n+1); F_n] = [F_(n+2); F_(n+1)]
```

行列とベクトルの積を関数にする。

```ocaml
let multiply_matrix_vector matrix vector =
  List.map (fun row -> dot row vector) matrix
```

行列累乗を使う実装は次のようになる。

```ocaml
let fibonacci n =
  if n < 0 then invalid_arg "fibonacci: negative input"
  else
    let transition = [[1; 1]; [1; 0]] in
    let transition_n =
      monoid_pow (matrix_monoid 2) transition n
    in
    match multiply_matrix_vector transition_n [1; 0] with
    | [_; fib_n] -> fib_n
    | _ -> failwith "fibonacci: unexpected vector shape"
```

```ocaml
List.init 11 fibonacci
(* [0; 1; 1; 2; 3; 5; 8; 13; 21; 34; 55] *)
```

### 遷移関数として捉える

さらに抽象化すると、行列は状態遷移関数を表現する実装の一つと考えられる。

```ocaml
type state = int * int

let fibonacci_step (next, current) =
  (next + current, next)

let fibonacci n =
  if n < 0 then invalid_arg "fibonacci: negative input"
  else
    let _, fib_n = repeat fibonacci_step n (1, 0) in
    fib_n
```

この形では、責務が明確に分かれる。

```text
fibonacci_step  1回分の状態遷移
repeat          遷移をn回合成する仕組み
(1, 0)          初期状態
```

行列累乗は大きな `n` に対して二分累乗を使える。一方、一般のブラックボックスな関数は、同じ関数を二乗しても実行時には内部で元の処理を2回行うため、関数合成だけで計算量が `O(log n)` になるわけではない。この違いは、行列のように「合成結果を小さな値として計算できる表現」を使う利点である。

## まとめ

今回の中心的な設計意図は、繰り返しの仕組みと1回分の処理を分離することだった。

最も直接的な表現は次の形になる。

```ocaml
repeat : ('a -> 'a) -> int -> 'a -> 'a
```

関数合成がモノイドを作ることを明示したい場合は、`endo_monoid` と `monoid_pow` を使って `repeat` を定義できる。

```ocaml
let repeat f n =
  monoid_pow endo_monoid f n
```

これによって、加算、乗算、状態遷移などの具体的な処理から、反復・合成の仕組みを独立させられる。行列はその状態遷移を合成可能なデータとして表す手段であり、二分累乗によって高速化できる点が特徴となる。
