## MVVM とは

MVVM（Model-View-ViewModel）は、UIの構築において**責務分離と疎結合**を実現するための設計パターンである。特にデータバインディングをサポートするフレームワーク（例: Vue.js, WPF, SwiftUIなど）と相性が良い。

### 各構成要素

| コンポーネント   | 役割                                  |
| --------- | ----------------------------------- |
| Model     | ビジネスロジックやデータの取得・操作を担当               |
| View      | ユーザーに表示されるUI部分。ViewModelにバインディングされる |
| ViewModel | ViewとModelの橋渡し役。データ整形・イベント処理を担当     |

ViewとViewModelは**バインディングによって接続**されており、ViewModelの状態が変化すれば自動でViewが更新される。逆に、ユーザー操作がViewを通じてViewModelに伝わることで、UIロジックがシンプルになる。

---

## MVC との違い

MVVMとMVC（Model-View-Controller）の最大の違いは、**UIの更新の仕組みとViewの責務の分離度**である。

| 項目        | MVC                     | MVVM                     |
| --------- | ----------------------- | ------------------------ |
| 仲介役       | Controller              | ViewModel                |
| Viewの更新方法 | Controllerが手動で更新        | ViewModelの状態変化によって自動更新   |
| Viewの責務   | 入力も出力も受け持つ              | 表示に専念し、ロジックはViewModelに委任 |
| 結合度       | ViewとControllerが密結合しやすい | ViewとViewModelは疎結合       |

MVCではUI更新のたびに明示的にViewの操作が必要なのに対し、MVVMではデータバインディングによって更新が**宣言的かつ自動**になる。

---

## MVVM と Reactive Programming の関係

MVVMは構造（アーキテクチャ）であり、Reactive Programming（リアクティブプログラミング）は振る舞い（パラダイム）である。

### 位置づけの違い

| 分類      | 例・説明                               |
| ------- | ---------------------------------- |
| アーキテクチャ | MVVM：構造の設計パターン                     |
| パラダイム   | Reactive Programming：データの流れに反応する手法 |

Reactive Programmingは、MVVMの中で特に**ViewとViewModel間のデータ同期**を実現する手段としてよく使われる。

> MVVMを実現するための手段の一つがReactive Programmingである。

代表的な組み合わせとして、Vue.jsの`ref()`/`computed()`、RxJSの`BehaviorSubject`、SwiftUIの`@Published`などがある。

---

## 実際のコードによる比較

### 共通仕様

* ToDoアプリ
* テキスト入力→追加ボタン→リストに反映

### MVC の例（バニラJS）

```html
<input id="todoInput" />
<button id="addBtn">追加</button>
<ul id="todoList"></ul>

<script>
  class TodoModel {
    constructor() { this.todos = []; }
    add(todo) { this.todos.push(todo); }
    getAll() { return this.todos; }
  }

  class TodoView {
    constructor() {
      this.input = document.getElementById('todoInput');
      this.addBtn = document.getElementById('addBtn');
      this.list = document.getElementById('todoList');
    }
    bindAdd(handler) {
      this.addBtn.addEventListener('click', () => {
        handler(this.input.value);
        this.input.value = '';
      });
    }
    render(todos) {
      this.list.innerHTML = '';
      todos.forEach(todo => {
        const li = document.createElement('li');
        li.textContent = todo;
        this.list.appendChild(li);
      });
    }
  }

  class TodoController {
    constructor(model, view) {
      this.model = model;
      this.view = view;
      this.view.bindAdd(this.handleAdd.bind(this));
      this.view.render(this.model.getAll());
    }
    handleAdd(todoText) {
      this.model.add(todoText);
      this.view.render(this.model.getAll());
    }
  }

  new TodoController(new TodoModel(), new TodoView());
</script>
```

### MVVM + RxJS の例

```html
<input id="todoInput" />
<button id="addBtn">追加</button>
<ul id="todoList"></ul>

<script src="https://unpkg.com/rxjs@7.5.7/dist/bundles/rxjs.umd.min.js"></script>
<script>
  const { BehaviorSubject } = rxjs;

  class TodoViewModel {
    constructor() {
      this.todos$ = new BehaviorSubject([]);
    }
    addTodo(todo) {
      const current = this.todos$.value;
      this.todos$.next([...current, todo]);
    }
  }

  class TodoView {
    constructor(vm) {
      this.input = document.getElementById('todoInput');
      this.addBtn = document.getElementById('addBtn');
      this.list = document.getElementById('todoList');
      this.vm = vm;

      this.addBtn.addEventListener('click', () => {
        this.vm.addTodo(this.input.value);
        this.input.value = '';
      });

      this.vm.todos$.subscribe(todos => this.render(todos));
    }

    render(todos) {
      this.list.innerHTML = '';
      todos.forEach(todo => {
        const li = document.createElement('li');
        li.textContent = todo;
        this.list.appendChild(li);
      });
    }
  }

  const vm = new TodoViewModel();
  new TodoView(vm);
</script>
```

### 比較まとめ

| 比較項目   | MVC                 | MVVM + RxJS           |
| ------ | ------------------- | --------------------- |
| View更新 | Controllerが手動で指示    | ViewModelの状態を購読して自動反映 |
| 結合度    | ViewとControllerは密結合 | ViewとViewModelは疎結合    |
| テスト性   | UI依存が強くテストしづらい      | ViewModel単体でテストしやすい   |
| 拡張性    | コードが複雑化しやすい         | 宣言的かつ再利用性が高い          |
