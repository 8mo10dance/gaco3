# Devbox 導入・使い方・Git管理まとめ

> ねらい：**ローカル開発環境を「プロジェクト単位」で再現可能にしつつ**、必要なら **グローバル（ユーザー全体）** のCLIツールも同じ思想で管理する。

---

## 1. Devbox とは

- Devbox は **Nix を土台にした開発環境マネージャ**。
- 依存を `devbox.json`（宣言）と `devbox.lock`（固定）で管理する。
- `devbox shell` で、そのプロジェクト専用のPATH/環境が立ち上がる。

> Nix の single-user / multi-user は **devboxが選ぶものではなく**、端末に入っている Nix に従う。

---

## 2. 導入（インストール）

### 2.1 Devbox のインストール

```bash
curl -fsSL https://get.jetpack.io/devbox | bash
```

確認：

```bash
devbox version
```

---

### 2.2 （任意）Nix を single-user で入れたい場合

Devbox だけを single-user にすることはできない。
**先に Nix を single-user（no-daemon）で導入**する。

```bash
sh <(curl -L https://nixos.org/nix/install) --no-daemon
```

> すでに multi-user Nix が入っている環境での切り替えは地雷が多いので、
> **新しいWSLディストリで最初から入れる**のが安全。

---

## 3. プロジェクトでの使い方（基本）

### 3.1 初期化

```bash
mkdir myapp
cd myapp

devbox init
```

作られるファイル：

- `devbox.json`（依存の宣言）
- `devbox.lock`（依存の固定）

---

### 3.2 パッケージ追加・削除

追加：

```bash
devbox add nodejs@20
```

削除：

```bash
devbox remove nodejs
```

一覧：

```bash
devbox list
```

---

### 3.3 シェルを起動

```bash
devbox shell
```

- この中では `node`, `ruby`, `jq` などが **プロジェクトの定義通り** に使える。
- 抜けると元に戻る（環境を汚しにくい）。

---

### 3.4 コマンドを直接実行

```bash
devbox run -- node -v
```

または `devbox.json` に scripts を定義して：

```json
{
  "packages": ["nodejs@20"],
  "shell": {
    "scripts": {
      "test": "npm test",
      "fmt": "npm run format"
    }
  }
}
```

実行：

```bash
devbox run test
```

---

## 4. devbox global（ユーザー全体のCLIツール管理）

### 4.1 何をするもの？

- `devbox global` は **ユーザー全体で使うツール箱**（ripgrep, fd, jq など）を管理する。
- プロジェクトと違い、どこにいても使いたい CLI を集約する用途。

追加：

```bash
devbox global add jq ripgrep fd
```

Task も global に入れておくと、プロジェクトごとの定型操作を `task` で統一しやすい。

```bash
devbox global add go-task
```

一覧：

```bash
devbox global list
```

場所確認：

```bash
devbox global path
```

> `~/.config` に無いことがあるのは正常。`global` は **XDG_DATA_HOME 配下**に作られることが多い。

シェル起動時に global の PATH を通す：

```bash
eval "$(devbox global shellenv)"
```

---

## 5. Git 管理の基本方針

### 5.1 プロジェクト（おすすめ）

**この2つをコミットする**：

- `devbox.json`
- `devbox.lock`

例：

```bash
git add devbox.json devbox.lock

git commit -m "Add devbox environment"
```

- `devbox.lock` があることで、チーム全員が同じ依存バージョンを再現しやすい。

---

### 5.2 グローバル環境を Git 管理したい

やり方は3つ。

#### A) devbox global push/pull（同期をdevboxに任せる）

保存：

```bash
devbox global push <git-remote>
```

復元：

```bash
devbox global pull <git-remote>
```

- 別PC/別WSLでも同じ global を再現したいときに楽。

#### B) dotfiles 管理（symlinkでガチ管理）

1) global の実体場所を確認：

```bash
devbox global path
```

2) `devbox.json` を dotfiles に置き、実体へ symlink：

```bash
# 例：dotfiles 側に置く
mkdir -p ~/dotfiles/devbox

# 例：globalのパスへリンク（パスは devbox global path の結果に合わせる）
ln -sf ~/dotfiles/devbox/devbox.json "$(devbox global path)/devbox.json"
```

- **XDG_DATA_HOME を変えなくて済む**（他アプリへの副作用がない）。
- dotfiles と一緒に `devbox.json` を管理できる。

#### C) chezmoi で管理する

chezmoi を使っているなら、global の `devbox.json` を chezmoi 管理にするのもよい。

管理候補：

- `~/.local/share/devbox/global/default/devbox.json`
- `.bashrc` / `.zshrc` などの `eval "$(devbox global shellenv)"` を書くシェル設定

`devbox.lock` は、global 環境まで厳密に固定したい場合だけ管理する。

---

## 6. よくあるハマりどころ

### 6.1 `devbox global` のファイルが見つからない

- まだ `devbox global add ...` を一度もしていない（作られてない）
- `XDG_DATA_HOME` によって場所が変わっている

確認：

```bash
devbox global path
```

---

### 6.2 Nix の experimental features（flakes / nix-command）

必要な場合：

```bash
mkdir -p ~/.config/nix
echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
```

一時的に回避：

```bash
nix --extra-experimental-features "nix-command flakes" <command>
```

---

### 6.3 Devbox / Nix の容量を掃除したい

Devbox は裏側で Nix store を使うため、容量の掃除は Nix 側の GC（garbage collection）で行う。
Devbox 自体に `devbox gc` が無いバージョンでは、次のコマンドを使う。

まず確認だけ：

```bash
nix store gc --dry-run
```

実際に消す：

```bash
nix store gc
```

`nix store gc` が動かない環境では、旧CLIのこれを使う：

```bash
nix-store --gc
```

削除対象の確認だけなら：

```bash
nix-store --gc --print-dead
```

指定した容量まで消す：

```bash
nix store gc --max 5G
```

古い profile generation が残っていると回収できないことがある。
より強めに掃除したい場合は、古い generation を消してから GC する。

```bash
nix profile wipe-history
nix store gc
```

旧CLIで強めに掃除するならこれでもよい：

```bash
nix-collect-garbage -d
```

> 今の Devbox プロジェクトや `devbox global` で参照中のパッケージは消えない。
> 不要なパッケージは先に `devbox rm <package>` や `devbox global rm <package>` で外してから GC する。

---

## 7. 運用のおすすめテンプレ

### 7.1 プロジェクト運用

- `devbox init`
- `devbox add ...`
- `devbox.json` / `devbox.lock` をコミット
- README に起動手順だけ書く

例：

```md
## Dev Setup

```bash
# 1) install devbox
# 2) enter shell

devbox shell
```
```

### 7.2 グローバル運用

- よく使うCLI：`devbox global add` で管理
- 共有したいなら `push/pull`、dotfiles統合なら symlink
- chezmoi を使うなら global の `devbox.json` とシェル設定を管理する

### 7.3 Task / Docker との役割分担

おすすめの分担：

- Devbox：Ruby, Node.js, AWS CLI, Task などの開発ツール・ランタイム
- Task：`bundle install` や `docker compose` 呼び出しなどのタスク実行
- Docker：LocalStack, MySQL, Redis, OpenSearch などの常駐サービス

Rails や Node は Devbox 上で動かし、DB や LocalStack のようなサービスだけ Docker に寄せると、ローカル実行とサービス管理を分けやすい。

Task で dip の interaction を置き換える例：

```yaml
version: "3"

tasks:
  bundle:
    cmds:
      - docker compose run --rm rails bundle {{.CLI_ARGS}}
```

実行：

```bash
task bundle -- install
```

`task bundle install` は `install` を別タスクとして解釈するので、引数は `--` の後ろに渡す。

### 7.4 Dockerfile 生成

Devbox から Dockerfile を生成できる。

```bash
devbox generate dockerfile
```

ローカルは Devbox、CI や配布用は Docker という使い分けをしたいときに便利。

---

## 付録：最小コマンド集

```bash
# project
cd myapp
devbox init
devbox add jq
devbox shell

# global
devbox global add ripgrep
devbox global add go-task
devbox global list
devbox global path
eval "$(devbox global shellenv)"

# dockerfile
devbox generate dockerfile

# cleanup
nix store gc --dry-run
nix store gc
nix-store --gc
nix profile wipe-history
nix-collect-garbage -d
```
