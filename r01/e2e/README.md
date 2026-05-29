# E2E テスト

[Playwright](https://playwright.dev/) を使用したE2Eテスト。

## 前提条件

- Node.js がインストールされていること
- Railsサーバーが `http://localhost:3000` で起動していること (`dip rails s`)

## セットアップ

依存パッケージとブラウザをインストールする。

```bash
cd e2e
npm install
npx playwright install chromium
```

Playwright のブラウザ実行に必要なOS側の依存ライブラリもインストールする。

```bash
npx playwright install-deps
```

`npx playwright test` 実行時に以下のようなエラーが出る場合は、Chromium の起動に必要な共有ライブラリが不足している。

```text
error while loading shared libraries: libnspr4.so: cannot open shared object file: No such file or directory
```

この場合も `npx playwright install-deps` を実行して依存ライブラリを入れる。

## 実行

```bash
cd e2e
npx playwright test
```

または npm scripts 経由で:

```bash
npm test               # ヘッドレスで実行
npm run test:headed    # ブラウザを表示して実行
npm run test:ui        # Playwright UI モードで実行
```

## 設定

`playwright.config.js` で設定を管理している。接続先URLは環境変数 `PLAYWRIGHT_BASE_URL` で変更できる（デフォルト: `http://127.0.0.1:3000`）。

```bash
PLAYWRIGHT_BASE_URL=http://staging.example.com npx playwright test
```
