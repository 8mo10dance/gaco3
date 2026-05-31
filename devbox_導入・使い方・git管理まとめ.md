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

一覧：

```bash
devbox global list
```

場所確認：

```bash
devbox global path
```

> `~/.config` に無いことがあるのは正常。`global` は **XDG_DATA_HOME 配下**に作られることが多い。

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

やり方は2つ。

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
devbox global list
devbox global path
```

