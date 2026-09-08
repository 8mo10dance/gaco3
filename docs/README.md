# 学習ドキュメント

個人学習用のメモを、テーマ別にまとめています。

## 言語

- [Ruby 学習メモ](./ruby-learning-notes.md) — Ruby の標準機能、コレクション、数値計算、`Module`、Monoid など
- [OCaml 学習メモ](./ocaml-learning-notes.md) — OCaml の基本構文、コレクション、関数、入出力、Seq など
- [モノイドによる繰り返しの抽象化](./monoid-repetition-abstraction.md) — 二分累乗、関数合成、行列による状態遷移
- [S式と人間言語についての考察](./s-expressions-and-human-language.md) — S式と Ruby 的構文の比較
- [Scheme 学習メモ](./scheme-learning-notes.md) — SRFI-1 の畳み込み、Guile の `identity`、`iota`、`use-modules` など

## フロントエンド

- [MVVM とは](./mvvm.md) — MVC、MVVM、Reactive Programming の関係
- [Reactive Programming for JS](./reactive-programming-for-js.md) — JavaScript のリアクティブな状態管理

## インフラ

- [AWS 学習メモ](./aws-learning-notes.md) — AWS、Terraform、Floci を使った学習記録
- [IaaS・PaaS・FaaS まとめ](./cloud-service-models.md) — クラウドサービスモデルと EC2、Fargate の比較

## ツール・環境構築

- [Devbox 導入・使い方・Git管理まとめ](./devbox-guide.md) — Devbox の導入、利用、設定管理
- [Docker on WSL2 トラブルシューティング](./docker-wsl2-troubleshooting.md) — 権限とクレデンシャル関連の問題
- [git-filter-repo --subdirectory-filter の整理](./git-filter-repo-subdirectory-filter.md) — サブディレクトリの履歴を切り出す方法
- [Yazi と Lazygit の組み合わせ方](./yazi-lazygit-integration.md) — Yazi から Lazygit を呼び出す設定
- [Rails アプリケーション作成用の環境構築](./rails-application-setup.md) — Docker と Makefile を使った `rails new`
- [Ruby 2.7 / Rails 6.0 の検証環境](./ruby-2-7-rails-6-validation-environment.md) — 旧バージョン向けの検証環境構築

## 設計・信頼性

- [へび問題から学んだ設計メモ](./snake-direction-design-notes.md) — 方角、座標、責務分離の設計
- [フェール・フォールト系まとめ](./failure-and-fault-tolerance-concepts.md) — フェールセーフなどの信頼性用語
