# git-filter-repo --subdirectory-filter の整理

## 概要

特定のサブディレクトリだけを切り出し、その中身をリポジトリのルートにしたい場合は `--subdirectory-filter` を使う。

```bash
git filter-repo --subdirectory-filter dir1
```

## 変換例

### 実行前

```text
repo/
├─ dir1/
│  ├─ app.rb
│  └─ Gemfile
├─ dir2/
└─ README.md
```

### 実行後

```text
repo/
├─ app.rb
└─ Gemfile
```

- `dir1` 以外のファイルやディレクトリは削除される
- `dir1` の中身がリポジトリのルートに移動する
- `dir1` に関係する履歴だけが残る
- コミット履歴も再構成される

## よくある用途

### Monorepo からサブプロジェクトを切り出す

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

## 注意点

### 履歴が書き換わる

`git filter-repo` は破壊的操作。

既存リポジトリで直接実行せず、通常は別クローンで作業する。

```bash
git clone <repo-url> extracted-repo
cd extracted-repo

git filter-repo --subdirectory-filter dir1
```

### リモートへ push する場合

履歴が変わるため、既存リモートへ反映するには通常 force push が必要。

```bash
git push --force origin main
```

## --path との違い

### --path

```bash
git filter-repo --path dir1/
```

結果:

```text
dir1/
└─ app.rb
```

ディレクトリ構造は保持される。

### --subdirectory-filter

```bash
git filter-repo --subdirectory-filter dir1
```

結果:

```text
app.rb
```

ディレクトリ自体が取り除かれ、中身がルートへ移動する。

## まとめ

`dir1` の中身をそのまま独立リポジトリにしたいなら、基本的には以下だけでよい。

```bash
git filter-repo --subdirectory-filter dir1
```
