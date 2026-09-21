# 隣接行列とグラフ探索

## 1. 隣接行列

グラフの隣接行列を \(M\) とすると、

\[
M_{ij}
\]

は頂点 \(i\) から頂点 \(j\) への辺を表す。

単純な非重み付きグラフなら、

\[
M_{ij} =
\begin{cases}
1 & i \rightarrow j \text{ の辺が存在する}\\
0 & \text{存在しない}
\end{cases}
\]

となる。

---

## 2. 隣接行列の累乗

行列積

\[
(M^2)_{ij}
=
\sum_k M_{ik}M_{kj}
\]

をグラフとして考えると、

\[
i \rightarrow k \rightarrow j
\]

という2ステップの経路を数えている。

一般に、

\[
(M^n)_{ij}
\]

は、

> 頂点 \(i\) から頂点 \(j\) へ、ちょうど \(n\) ステップで到達する walk の数

を表す。

したがって、

\[
(M^n)_{ij}>0
\]

なら、\(i\) から \(j\) へちょうど \(n\) ステップで到達可能。

頂点 \(i\) から \(n\) ステップで到達可能な頂点集合は、

\[
\{j \mid (M^n)_{ij}>0\}
\]

となる。

### nステップ以内で到達可能な頂点

「ちょうど \(n\) ステップ」ではなく「\(n\) ステップ以内」なら、

\[
I+M+M^2+\cdots+M^n
\]

を考える。

\[
(I+M+\cdots+M^n)_{ij}>0
\]

なら、\(i\) から \(j\) へ \(n\) ステップ以内で到達可能。

---

## 3. 行列積と経路の合成

一般的な行列積

\[
C_{ij}
=
\sum_k A_{ik}B_{kj}
\]

は、グラフとして見ると

```text
i ──A──→ k ──B──→ j
```

という経路を考えている。

つまり行列積は、

> 経路をつなげる操作

として解釈できる。

そのため、

\[
M^2 = M \cdot M
\]

は「1ステップ + 1ステップ」、

\[
M^3 = M^2 \cdot M
\]

は「2ステップ + 1ステップ」を表す。

---

## 4. Boolean行列

単に「到達可能かどうか」だけを知りたいなら、通常の加算・乗算の代わりに

- 加算 → OR
- 乗算 → AND

を使うこともできる。

\[
C_{ij}
=
\bigvee_k(A_{ik}\land B_{kj})
\]

この場合、\((M^n)_{ij}\) は、

> \(i\) から \(j\) へちょうど \(n\) ステップで到達可能か

を直接表す。

このように、行列演算に使う「足し算」「掛け算」を変えることで、グラフ上で求めるものを変えられる。これは半環（Semiring）につながる考え方。

---

## 5. 隣接行列の累乗が数えるのは walk

注意点として、\(M^n\) が数える経路では同じ頂点を何度通ってもよい。

例えば、

```text
A → B → C
    ↑   ↓
    └───┘
```

なら、

```text
A → B → C → B → C
```

も \(M^4\) に含まれる。これは **walk** と呼ばれる。

一方、

> 同じ頂点を2回通らない経路

は **simple path（単純路）** と呼ばれる。

---

## 6. simple pathでは履歴が必要

walkの場合、探索状態として

\[
\text{現在の頂点}
\]

だけ覚えていればよい。

しかしsimple pathでは、

\[
(\text{現在の頂点}, \text{訪問済み頂点集合})
\]

を覚える必要がある。

例えば、

```text
A → B → C
```

まで来たなら、

```text
current = C
visited = {A, B, C}
```

という情報が必要。

隣接行列の通常の累乗では「途中でどの頂点を通ったか」という履歴が失われるため、simple pathをそのまま求めることはできない。

---

# DFSとBFS

## 7. DFS

DFS（Depth First Search）は、深い方向を優先して探索する。

典型的な再帰実装：

```ruby
def dfs(graph, v, visited)
  return if visited[v]

  visited[v] = true
  puts v

  graph[v].each do |next_v|
    dfs(graph, next_v, visited)
  end
end
```

再帰を使わずにStackで書くこともできる。

```ruby
def dfs(graph, start)
  visited = Array.new(graph.size, false)
  stack = [start]

  until stack.empty?
    v = stack.pop

    next if visited[v]

    visited[v] = true
    puts v

    graph[v].reverse_each do |next_v|
      stack << next_v unless visited[next_v]
    end
  end
end
```

再帰版では、言語処理系のコールスタックが暗黙的なStackとして働いている。

つまり、

> 再帰だからDFSなのではなく、再帰のコールスタックをfrontierとして利用するとDFSになる。

---

## 8. BFS

BFS（Breadth First Search）は、浅い頂点から順番に探索する。

典型的にはQueueを使う。

```ruby
queue = [start]

until queue.empty?
  v = queue.shift

  graph[v].each do |next_v|
    queue << next_v
  end
end
```

---

## 9. DFSとBFSの違い

DFSとBFSはどちらも、

```text
未探索の候補をfrontierに入れる
        ↓
frontierから次の状態を取り出す
        ↓
そこから新しい候補を追加する
```

という同じ構造を持つ。

違うのは、

> frontierから次にどの状態を取り出すか

という戦略。

| 探索 | frontier | 優先するもの |
|---|---|---|
| DFS | Stack（LIFO） | 深い状態 |
| BFS | Queue（FIFO） | 浅い状態 |
| Dijkstra | Priority Queue | 累積コストが小さい状態 |
| A* | Priority Queue | 累積コスト + 推定残距離が小さい状態 |

したがって、

\[
\boxed{\text{探索アルゴリズム} = \text{frontierから次に何を選ぶか}}
\]

という形で統一的に考えられる。

---

## 10. BFSも再帰で書ける

再帰そのものはDFSを意味しない。

Queueを状態として持てば、BFSも再帰で書ける。

```ruby
def bfs(graph, queue, visited)
  return if queue.empty?

  v = queue.shift
  return bfs(graph, queue, visited) if visited.include?(v)

  visited << v
  puts v

  graph[v].each do |next_v|
    queue << next_v unless visited.include?(next_v)
  end

  bfs(graph, queue, visited)
end
```

---

## 11. BFSを「層の再帰」として考える

BFSでは、同じ深さの頂点をひとまとまりとして考えることもできる。

例えば、

```text
        A
      /   \
     B     C
    / \     \
   D   E     F
```

なら、

```text
[A]
 ↓
[B, C]
 ↓
[D, E, F]
 ↓
[]
```

と探索できる。

数学的には、

\[
L_0=\{start\}
\]

として、

\[
L_{n+1}
=
\left(
\bigcup_{v\in L_n} neighbors(v)
\right)
-
visited
\]

と次の層を生成していく。

Rubyなら、

```ruby
def bfs(graph, vertices, visited = Set.new)
  return if vertices.empty?

  vertices.each { |v| puts v }

  visited.merge(vertices)

  next_vertices =
    vertices
      .flat_map { |v| graph[v] }
      .reject { |v| visited.include?(v) }
      .uniq

  bfs(graph, next_vertices, visited)
end
```

と書ける。

---

# 全体の見方

隣接行列とグラフ探索は、一見別の話に見えるが、

> 「ある状態から、次にどの状態へ進めるか」

を繰り返し計算している点では共通している。

隣接行列では、\(M^n\) によって「遷移を \(n\) 回合成する」。

DFS/BFSでは、

```text
current
  ↓
neighbors
  ↓
frontier
  ↓
next current
```

と状態を展開していく。

さらにDFS、BFS、Dijkstra、A*の違いは、基本的には **frontierから次の状態を選択する規則**の違いとして捉えられる。

一方、simple pathのように過去の情報が必要な問題では、\(current\) だけでは状態が足りず、\((current, visited)\) のように状態空間そのものを拡張する必要がある。

この観点から見ると、グラフ探索は

\[
\boxed{
\text{状態}
+
\text{遷移}
+
\text{frontierの選択戦略}
}
\]

として整理できる。
