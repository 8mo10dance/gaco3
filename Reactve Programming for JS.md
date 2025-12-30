# Reactive Programming for JS

## モダンフロントエンドにおける状態管理の比較 (React vs Solid)

### 1. React の状態管理モデル

1. **状態の保持主体**: React では状態（state）はコンポーネント自身が保持する。`useState` や `useReducer` などの Hook を通して、コンポーネント関数が直接「状態スロット」を React に登録し、更新のたびにコンポーネント全体を再レンダリングする。
2. **再レンダリングの仕組み**: 状態を更新する（例: `setCount`）と、そのコンポーネント関数を再実行して新しい仮想 DOM (Virtual DOM) を生成。React の差分検出アルゴリズムによって実際の DOM を必要最小限だけ更新する。
3. **依存配列による副作用管理**: `useEffect` では依存配列を明示的に渡し、「特定の state/prop が変わったら実行する」副作用を定義。副作用の依存関係は明示的に記述する必要がある。
4. **グローバルステートの扱い**: コンポーネント間で状態を共有したい場合、Context API や Redux/Recoil/Zustand/MobX などの外部ライブラリを導入して「コンポーネント外にストアを用意し、Hook で購読する」方式が一般的。

### 2. Solid.js の状態管理モデル

1. **シグナル (signal) の定義**: `createSignal` を呼ぶと「リアクティブな値の入れ物 (Signal)」が返り、`count()` で読み取り、`setCount(...)` で更新すると、Signal に依存している箇所だけが再実行される。
2. **細粒度の依存トラッキング**: `createSignal` と `createEffect` や `createMemo` を組み合わせることで、自動的にどの計算や UI 部分がその Signal に依存しているかをランタイムがトラッキングし、更新時に必要最低限の再実行を行う。
3. **Virtual DOM を介さない更新**: Solid は Virtual DOM を使わず、リアクティブラップされた関数や effect が直接 DOM を操作・差分更新するため、オーバーヘッドが小さい。
4. **コンポーネント外での定義**: モジュールスコープで `createSignal` を呼べば、コンポーネントとは独立したグローバルなリアクティブ状態を作成できる。コンポーネント内で呼ぶと自動的にそのコンポーネントのリアクティブルートに紐づき、アンマウント時にクリーンアップされる。

### 3. React と Solid の比較まとめ

| 項目               | React (`useState`/`useEffect`)       | Solid.js (`createSignal`/`createEffect`) |
| ---------------- | ------------------------------------ | ---------------------------------------- |
| 状態の保持主体          | コンポーネントが主体 (`useState` はコンポーネント内限定)  | オブジェクト (Signal) 自体が主体。モジュール外でも定義可能       |
| 依存トラッキングの粒度      | コンポーネント単位で再レンダリング → Virtual DOM 差分検出 | Signal 単位で細粒度トラッキングし、依存先だけを再実行           |
| 再レンダリングの仕組み      | 状態更新時にコンポーネントを再実行 → Virtual DOM 差分   | Signal 変更時に依存しているエフェクトや JSX 部分を直接更新      |
| Virtual DOM の使用  | あり                                   | なし                                       |
| グローバルステートの定義     | Context や外部ライブラリが必要                  | モジュールスコープで `createSignal` を呼ぶだけで共有可能     |
| SSR/ハイドレーションの容易さ | Virtual DOM モデルに最適化されている             | 明示的な reactive root 管理が必要                 |

## リアクティブなオブジェクトとは？

### 1. リアクティブオブジェクトの定義

* リアクティブオブジェクトとは、**オブジェクト自身が「プロパティの読み書き」を検知し、依存している処理を自動で再実行する仕組みを持つ**オブジェクトを指します。
* 具体的には、`Proxy` や `getter`/`setter` を活用して、以下を実現できるものを「リアクティブオブジェクト」と呼びます。

  1. **依存トラッキング**: あるプロパティを読み取ったとき、そのプロパティに依存する関数（computed / effect / UI 部分）を記録する。
  2. **通知 (Trigger)**: そのプロパティを書き換えたとき、依存トラッキングで記録された関数を再実行する。

### 2. 代表的な実装例

1. **Vue の `reactive` / `ref`**

   * `reactive({ count: 0 })` でオブジェクト全体を Proxy 化し、プロパティ単位で依存を記録・通知。
   * `ref(0)` はプリミティブ値をラップし、内部で `value` プロパティを通じて依存トラッキングと通知を実装する。

2. **MobX**

   * クラスやオブジェクトに `makeAutoObservable(this)` を適用すると、すべてのプロパティを observable（リアクティブ化）し、getter 呼び出し → 依存トラッキング、setter 呼び出し → 通知 を実装する。

3. **Solid.js の `createSignal`**

   * `const [count, setCount] = createSignal(0)` で Signal を生成し、`count()` 読み取り → 依存トラッキング、`setCount(newVal)` → 通知 で依存先のみ再実行する。

4. **Valtio**

   * `const state = proxy({ count: 0 })` でオブジェクトを Proxy 化し、`state.count` 更新 → 変更通知、`subscribe(state, callback)` で購読。

5. **RxJS / BehaviorSubject**

   * `const count$ = new BehaviorSubject(0)` でストリームを作り、`count$.subscribe()` で購読、`count$.next(newVal)` で通知。

### 3. リアクティブオブジェクトの利点と課題

#### 利点

1. **最小限差分更新**: 変更があったプロパティに依存する箇所だけを再計算／再描画できる。
2. **宣言的で自動化された依存管理**: 依存配列を明示的に書かなくても、getter 呼び出しでトラッキングが自動的に行われる。
3. **グローバルステートの共有が容易**: モジュールスコープで定義すれば、どのコンポーネントでも同じオブジェクトを参照・更新できる。

#### 課題

1. **ランタイムオーバーヘッド**: Proxy や依存トラッキングをランタイムで行うコストがあるため、大規模アプリではパフォーマンスのチューニングが必要。
2. **デバッグの複雑化**: どのタイミングでどの依存が再実行されるかが暗黙的になるため、バグのトレースが難しい場合がある。
3. **SSR/ハイドレーションの設計**: サーバーサイドレンダリングで依存トラッキングを再現する、ハイドレーション後にシグナルを復元するなど、設計に配慮が必要。

## バニラJS以上、React 未満の状態管理

### 1. 状況整理

* **バニラ JS だけでシンプルにリアクティブ更新を行いたい**が、React のようにコンポーネントをフルに使わずに、**最小限のコードで状態管理を外部化したい**場合がある。
* **Stimulus.js や Alpine.js のような軽量ライブラリ** と組み合わせ、**HTML + 少量の JS で状態をリアクティブに管理**したい場合も増えている。

### 2. Valtio を使ったシンプルなバニラ JS 例

```html
<!-- index.html -->
<div>
  <h1>Count: <span id="count">0</span></h1>
  <button id="btn-inc">＋1</button>
  <button id="btn-reset">リセット</button>
</div>

<script type="module">
  import { proxy, subscribe, snapshot } from 'https://cdn.jsdelivr.net/npm/valtio@1.11.1/esm/index.mjs';

  // ストア定義
  const store = proxy({ count: 0 });

  // 変更を監視して DOM を更新
  subscribe(store, () => {
    const snap = snapshot(store);
    document.getElementById('count').textContent = snap.count;
  });

  // ボタンクリックで状態更新
  document.getElementById('btn-inc').addEventListener('click', () => {
    store.count += 1;
  });
  document.getElementById('btn-reset').addEventListener('click', () => {
    store.count = 0;
  });

  // 初期値同期
  document.getElementById('count').textContent = snapshot(store).count;
</script>
```

* **構成**: ただのオブジェクトを `proxy()` でリアクティブ化し、`subscribe()` → `snapshot()` → DOM 書き換え という流れ。
* **特徴**: React やその他フレームワークをまったく使わずに、**純粋な HTML + JS だけでリアクティブ更新**が可能。

### 3. Stimulus.js と Valtio の組み合わせ例

```html
<!-- index.html -->
<div data-controller="counter">
  <h1>Count: <span data-counter-target="value">0</span></h1>
  <button data-action="click->counter#increment">＋1</button>
  <button data-action="click->counter#reset">リセット</button>
</div>
<script type="module" src="./js/application.js"></script>
```

```js
// js/store/counterStore.js
import { proxy, subscribe, snapshot } from 'valtio';
export const counterStore = proxy({ count: 0 });
export const subscribeCounter = (callback) => subscribe(counterStore, callback);
export const getCounterSnapshot = () => snapshot(counterStore);

// js/controllers/counter_controller.js
import { Controller } from '@hotwired/stimulus';
import { counterStore, subscribeCounter, getCounterSnapshot } from '../store/counterStore';

export default class extends Controller {
  static targets = ['value'];

  connect() {
    // 初期表示
    this.valueTarget.textContent = getCounterSnapshot().count;
    // 変更監視登録
    this.unsubscribe = subscribeCounter(() => {
      const snap = getCounterSnapshot();
      this.valueTarget.textContent = snap.count;
    });
  }

  disconnect() {
    // 購読解除
    if (this.unsubscribe) this.unsubscribe();
  }

  increment() {
    counterStore.count += 1;
  }

  reset() {
    counterStore.count = 0;
  }
}

// js/application.js
import { Application } from '@hotwired/stimulus';
import CounterController from './controllers/counter_controller';

const application = Application.start();
application.register('counter', CounterController);
```

* **構成**

  1. `counterStore` をモジュールスコープで proxy 化して定義。
  2. Stimulus の `connect()` で `subscribeCounter()` を呼び、ストア変更時に DOM (`valueTarget`) を更新。
  3. `increment()` や `reset()` でストアを書き換えるだけで自動的に表示が更新される。

* **特徴**

  * Stimulus のデータ属性やコントローラを使って UI の構造・イベントを定義し、状態更新ロジックは Valtio ストアに任せる。
  * HTML と JS を最小限に保ったまま、**「軽量にリアクティブな UI を実現」** できる。

### 4. ライブラリ選定のポイント

1. **バニラ JS＋極限に近い軽量さ** → Valtio の Proxy + subscribe/snapshot のみで十分。
2. **軽量な MVC/MVVM ライブラリと組み合わせ** → Stimulus.js / Alpine.js と組み合わせ。コンポーネント構造をディレクティブで定義しつつ、Valtio で状態更新部分だけをリアクティブにする。
3. **軽量フレームワーク (Preact / Solid)＋JSX だけ使いたい** → 例えば Preact などで JSX を書きつつ、Valtio を外部ストアとして購読するパターンも同様に可能。

---

以上のように、**「バニラ JS / Stimulus.js のような軽量ライブラリ + Valtio の Proxy ベースリアクティブストア」** の組み合わせは、
React のような重めの状態管理を避けたいときや、JSX を使わずにシンプルに UI を作りたいときに非常に適した選択肢を提供します。
