# Yazi と Lazygit の組み合わせ方

## 何ができるか

Yazi から `lazygit` を起動して、ファイル操作と Git 操作を行き来できる。

Yazi をファイラ、`lazygit` を Git 操作用 TUI として使い分ける形になる。

---

## 基本の流れ

1. Yazi を開く
2. 任意のディレクトリへ移動する
3. Yazi から `lazygit` を起動する
4. Git 操作が終わったら Yazi に戻る

---

## 準備

### `ya pkg` とは？

`ya pkg` は Yazi 用のプラグインマネージャ。

### plugin のインストール

```bash
ya pkg add Lil-Dank/lazygit
```

### インストール済み plugin の確認

```bash
ya pkg list
```

---

## Yazi から lazygit を起動する設定

### キーバインド例

`~/.config/yazi/keymap.toml`

```toml
[[manager.prepend_keymap]]
on = ["g", "g"]
run = "plugin lazygit"
```

この例では `gg` で `lazygit` を起動できる。

---

## 関連する Yazi 設定

### 設定ディレクトリ

```txt
~/.config/yazi/
```

### よく触るファイル

`yazi.toml`

メイン設定。

`keymap.toml`

キーバインド設定。`lazygit` 起動キーを足すならここを編集する。

`theme.toml`

テーマ設定。

`plugins/`

plugin 本体が配置される。

---

## chezmoi で管理する場合

### `plugins/` を管理するべきか

基本的には **管理しないほうがよい**。

理由:

- 外部 plugin のコピーだから
- `ya pkg` で再取得できるから
- `plugins/` まで dotfiles 管理すると更新差分が見えにくくなりやすいから

管理対象にするなら、通常は `keymap.toml` などの自分の設定だけで十分。
