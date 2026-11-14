# git-filter-repo によるリポジトリの切り出しと統合

## 操作の違い

| オプション | 操作 | 変換例 |
| --- | --- | --- |
| `--subdirectory-filter dir1` | 特定ディレクトリを切り出してルートに移す | `dir1/app.rb` → `app.rb` |
| `--to-subdirectory-filter vendor/repo-b` | リポジトリ全体を指定ディレクトリの下に移す | `app.rb` → `vendor/repo-b/app.rb` |

## 履歴を書き換える際の共通注意点

`git filter-repo` は履歴を書き換える操作です。元リポジトリのバックアップを確保し、必ず別クローンで実行してください。コミットIDが変わり、署名付きコミット・タグの署名も維持できません。

```bash
git clone --no-local /path/to/source /path/to/filtered-copy
cd /path/to/filtered-copy
```

新規クローンの安全確認で拒否された場合は原因を確認し、コピーを作り直してください。安易に `--force` を追加しないでください。

## 特定ディレクトリを別リポジトリへ切り出す

特定のサブディレクトリだけを切り出し、その中身をリポジトリのルートにしたい場合は `--subdirectory-filter` を使う。

```bash
git filter-repo --subdirectory-filter dir1
```

### 変換例

#### 実行前

```text
repo/
├─ dir1/
│  ├─ app.rb
│  └─ Gemfile
├─ dir2/
└─ README.md
```

#### 実行後

```text
repo/
├─ app.rb
└─ Gemfile
```

- `dir1` 以外のファイルやディレクトリは削除される
- `dir1` の中身がリポジトリのルートに移動する
- `dir1` に関係する履歴だけが残る
- コミット履歴も再構成される

### よくある用途

#### Monorepo からサブプロジェクトを切り出す

```text
monorepo/
├─ frontend/
├─ backend/
└─ docs/
```

`backend` だけ独立したリポジトリにしたい場合:

```bash
git filter-repo --subdirectory-filter backend
```

### --path との違い

#### --path

```bash
git filter-repo --path dir1/
```

結果:

```text
dir1/
└─ app.rb
```

ディレクトリ構造は保持される。

#### --subdirectory-filter

```bash
git filter-repo --subdirectory-filter dir1
```

結果:

```text
app.rb
```

ディレクトリ自体が取り除かれ、中身がルートへ移動する。

### 切り出し後の公開

新しいリポジトリへの公開と、既存リモートの履歴を置き換える操作は区別してください。切り出した履歴で既存リモートのブランチを置き換える場合に限り、通常は強制プッシュが必要です。共同作業者への影響とバックアップを確認してから実行します。

`filter-repo` によって `origin` が削除されている場合は、公開先を確認してリモートを再設定してください。

```bash
# 既存リモートの履歴を意図的に置き換える場合のみ
# origin が正しい公開先を指すことを確認して実行する
git push --force origin main
```

## 別リポジトリを特定ディレクトリへ取り込む

既存の `repo-a` に、別リポジトリ `repo-b` を `vendor/repo-b/` として取り込む手順です。どちらの方法も、取り込むブランチから到達できるコミット履歴を統合できます。

```text
repo-a/
├── README.md
├── src/
└── vendor/
    └── repo-b/
        ├── README.md
        └── src/
```

### 方法の選び方

| 方法 | 元のコミットID | 取り込み前の履歴のパス | 向いている用途 |
| --- | --- | --- | --- |
| `filter-repo` → `merge` | 取り込み元のIDを書き換える | `vendor/repo-b/` 以下へ書き換える | 過去の履歴も統合後のディレクトリ構成にそろえる |
| `subtree add`（`--squash` なし） | 取り込み元のIDを維持する | 元のリポジトリのパスのまま | 手軽な取り込み、元リポジトリとの継続的な同期 |

`--subdirectory-filter` は特定ディレクトリを抽出してルートに移す操作です。逆に、リポジトリ全体をディレクトリの下へ移すには `--to-subdirectory-filter` を使います。[git-filter-repo公式マニュアル](https://github.com/newren/git-filter-repo/blob/main/Documentation/git-filter-repo.txt)

### 共通の準備

- 以下の `/path/to/repo-a`、`/path/to/repo-b`、`/path/to/repo-b-filtered` を実際のパスに置き換えます。コピー先はまだ存在しない場所を指定します。
- 取り込み元のブランチを `main` と仮定します。`master` などの場合は読み替えてください。
- 作業中の変更はコミットするか退避し、`git status` で作業ツリーがクリーンなことを確認します。
- 元リポジトリのバックアップを確保し、取り込み先では作業用ブランチを作ります。
- 取り込み先ディレクトリは未作成の場所を選ぶと安全です。方法2の `subtree add` では、指定したディレクトリが存在しないことが必要です。

```bash
cd /path/to/repo-a
git status
git switch -c import/repo-b
```

方法1・方法2は代替手順です。同じブランチで両方を実行しないでください。

### 方法1：git filter-repo と git merge を使う

#### 1. コマンドの利用可否を確認する

`git-filter-repo` はGit本体とは別に導入します。

```bash
git filter-repo --version
```

利用できない場合は、[公式の導入手順](https://github.com/newren/git-filter-repo#how-do-i-install-it)に従ってインストールしてください。

#### 2. 取り込み元をコピーして、履歴内のパスを書き換える

```bash
git clone --no-local /path/to/repo-b /path/to/repo-b-filtered
cd /path/to/repo-b-filtered

git filter-repo --to-subdirectory-filter vendor/repo-b
```

`--no-local` はローカルパスからのクローンでも通常の転送処理を使い、新規クローンとして履歴を書き換えるための指定です。履歴の書き換えは必ずコピー側で実行します。安全確認で拒否された場合は原因を確認し、新しいクローンを作り直してください。安易に `--force` を追加しないでください。

これにより、処理対象の履歴中のファイルパスが `vendor/repo-b/` 以下になります。パスの変更に伴い、取り込み元のコミットIDも変わります。`filter-repo` がコピー側の `origin` を削除することがありますが、次の手順はその `origin` を使いません。[git-filter-repo公式マニュアル](https://github.com/newren/git-filter-repo/blob/main/Documentation/git-filter-repo.txt)

#### 3. 取り込み先にマージする

```bash
cd /path/to/repo-a

git remote add repo-b-import /path/to/repo-b-filtered
git fetch --no-tags repo-b-import

git merge --allow-unrelated-histories --no-ff \
  -m "Import repo-b into vendor/repo-b with history" \
  repo-b-import/main
```

`--allow-unrelated-histories` は、共通の祖先を持たない独立した履歴のマージを許可します。取り込み先の既存コミットIDは維持され、両方の履歴をつなぐマージコミットが作られます。[git merge公式ドキュメント](https://git-scm.com/docs/git-merge)

競合が発生した場合は、内容を確認して解消してから次を実行します。

```bash
git add <解消したファイル>
git merge --continue
```

進行中のマージを取り消す場合は次を実行します。

```bash
git merge --abort
```

#### 4. 結果を確認して、一時的なリモートを外す

```bash
git status
git log --oneline --graph --all
git log --oneline -- vendor/repo-b/
git ls-tree -r --name-only HEAD -- vendor/repo-b/

git remote remove repo-b-import
```

リモートを削除しても、マージ済みコミットは取り込み先の履歴に残ります。ただし、マージしていない別ブランチを保存するには、別途そのブランチへのローカル参照が必要です。ビルドやテストも実行し、取り込み後の動作を確認してください。

### 方法2：git subtree add を使う

履歴のパスを書き換えずに取り込むなら、`git subtree add` が手軽です。以下は共通の準備を済ませた `repo-a` で実行します。

```bash
cd /path/to/repo-a

git remote add repo-b-upstream /path/to/repo-b
git subtree add --prefix=vendor/repo-b repo-b-upstream main
```

`git subtree add <repository> <remote-ref>` は必要な取得処理も行うため、事前の `git fetch` は不要です。`git subtree` が使えない環境では、利用中のGit配布物に応じて追加導入してください。

**履歴を保持する場合は `--squash` を付けません。** 通常の `add` は取り込み元の履歴をつなぐコミットを作ります。`--squash` を付けると、その取り込みでは個々の元コミットを祖先としてつなぎません。[git subtree公式ドキュメント](https://github.com/git/git/blob/master/contrib/subtree/git-subtree.adoc)

#### 履歴の確認

```bash
git log --oneline --graph --all
git log --oneline repo-b-upstream/main
git ls-tree -r --name-only HEAD -- vendor/repo-b/
```

`subtree` では、元コミットは元のパスのまま履歴に残ります。そのため `git log -- vendor/repo-b/` だけでは、取り込み前の履歴を十分に表示できません。全体のグラフや元ブランチの履歴も確認してください。

#### 元リポジトリの更新を後から取り込む

```bash
git subtree pull --prefix=vendor/repo-b repo-b-upstream main
```

最初に `--squash` なしで取り込んだ場合は、更新時も同じ方針で運用します。一度きりの取り込みなら、確認後にリモートを外しても取り込み済みの履歴は残ります。

```bash
git remote remove repo-b-upstream
```

### 注意点

#### 履歴とブランチ・タグの範囲

ここで統合するのは、指定した `main` から到達できる履歴です。元リポジトリの全ブランチやタグが、同名のブランチ・タグとして取り込み先に保存されるわけではありません。

方法1ではタグ名の衝突を避けるため、取得時に `--no-tags` を指定しています。タグも必要なら、コピー側でのタグ名の変更や、取り込み先での名前空間を設計してから別途取得してください。例として、履歴の書き換え時に `--tag-rename '':'repo-b-'` を追加すれば、タグ名へ接頭辞を付けられます。

#### コミットIDと既存履歴

方法1は取り込み元の履歴を書き換えるため、元のコミットIDを指すリンクや参照は、そのままでは書き換え後の履歴を指しません。共通注意点も確認してください。取り込み先の既存履歴を書き換える必要はなく、この手順だけを理由とする強制プッシュも不要です。

#### パスや運用設定の調整

ファイルを移動しても、ソースコード中のパス、ビルド設定、CI、依存関係の参照が自動で直るわけではありません。元リポジトリの `.github/` や `.gitignore` もサブディレクトリに入るため、統合先での配置や適用範囲を確認してください。

#### Git管理外のデータ

未コミット・未追跡ファイル、GitHub等のIssue・Pull Request・リポジトリ設定は、この操作では取り込まれません。Git LFSの実体やサブモジュールも、別途取得・移行の確認が必要です。

#### 公開前の確認

過去の履歴も取り込むため、ライセンス、秘密情報、大容量ファイルを含む過去のコミットを確認してください。内容と動作の検証後、作業用ブランチを通常の手順でレビュー・統合・プッシュします。

## 参考資料

- [git-filter-repo公式リポジトリ・導入案内](https://github.com/newren/git-filter-repo)
- [git-filter-repo公式マニュアル](https://github.com/newren/git-filter-repo/blob/main/Documentation/git-filter-repo.txt)
- [git merge公式ドキュメント](https://git-scm.com/docs/git-merge)
- [git subtree公式ドキュメント](https://github.com/git/git/blob/master/contrib/subtree/git-subtree.adoc)
