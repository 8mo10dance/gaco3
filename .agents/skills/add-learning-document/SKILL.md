---
name: add-learning-document
description: Provide a supplied learning note as a new docs/ Markdown document, update its category index, and validate the documentation set. Use for repository learning notes, not project README files.
---

# 学習ドキュメントの追加

ユーザーから渡されたメモや文章を、このリポジトリの `docs/` にある学習ドキュメントとして追加する。

## 作業方針

- 素材の意味を保って読みやすい Markdown に整理する。依頼がない限り、外部調査、事実の更新、内容の創作はしない。
- 追加先は `docs/<english-kebab-case>.md` とする。既存ファイル名との衝突を確認する。
- 文書には H1 を1つだけ置き、見出し階層を飛ばさない。コードブロックには言語を指定し、相対リンクは実在するファイルを指すようにする。
- 既存文書と主題が実質的に重複する場合は、統合や上書きをせず、追加か統合かをユーザーに確認する。
- `docs/README.md` を読み、最も近い既存カテゴリへ日本語のタイトルと一行説明を追記する。適切なカテゴリがなければ、新しい簡潔なカテゴリを追加する。
- `docs/` 配下の Markdown は `0644` にする。
- コミットは、ユーザーから明示的に依頼された場合だけ行う。

## 手順

1. `docs/README.md` と関連する既存文書を読んで、ファイル名・書式・カテゴリを決める。
2. 新規文書と索引を更新する。
3. `chmod 0644 docs/<filename>.md` を実行する。
4. 次をリポジトリルートで実行する。

   ```bash
   python3 .agents/skills/add-learning-document/scripts/validate_docs.py
   git diff --check
   ```

5. 検証エラーを修正し、変更した文書、索引、検証結果を報告する。

例: `$add-learning-document この OCaml のメモを docs に追加して: ...`
