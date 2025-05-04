## 新卒研修: Rails 7.2 + Rspack サンプルプロジェクト

### 0. 研修準備：サンプルプロジェクトの作成手順

1. **プロジェクトディレクトリ作成**
   ```bash
   mkdir myapp && cd myapp
   ```
2. **Rails アプリ初期化 (backend)**
   ```bash
   rails _7.2.0_ new backend --skip-javascript --skip-test
   ```
3. **フロントエンド初期化 (frontend)**
    ```bash
    mkdir frontend && cd frontend
    npm init -y
    npm install --save-dev @rspack/cli @rspack/core @babel/core @babel/preset-env @babel/preset-typescript @babel/preset-react typescript react react-dom style-loader css-loader babel-loader @types/react @types/react-dom
    cd ..
    ```

    package.json に build スクリプトを追加
    ```json
    {
      "scripts": {
        "build": "rspack --config rspack.config.js"
      }
    }
    ```

4. **設定ファイル作成**

    **.babelrc**

    ```json
    {
      "presets": [
        ["@babel/preset-env", { "targets": { "browsers": "last 2 versions" } }],
        "@babel/preset-typescript",
        "@babel/preset-react"
      ]
    }
    ```

    **tsconfig.json**

    ```json
    {
      "compilerOptions": {
        "target": "ES6",
        "module": "ESNext",
        "jsx": "react-jsx",
        "strict": true,
        "moduleResolution": "node"
      },
      "include": ["src"]
    }
    ```

    **rspack.config.js**

    ```javascript
    const path = require('path');
    module.exports = {
      entry: './frontend/src/index.js',
      output: {
        path: path.resolve(__dirname, 'public', 'packs'),
        filename: 'bundle.js',
        publicPath: '/packs/'
      },
      module: {
        rules: [
          { test: /\.css$/, use: ['style-loader', 'css-loader'] },
          { test: /\.(png|jpg|gif)$/, type: 'asset/resource' },
          { test: /\.(ts|tsx)$/, use: 'babel-loader' }
        ]
      },
      resolve: { extensions: ['.js', '.ts', '.tsx'] }
    };
    ```

5. **Docker 環境構築**
   ```bash
   touch Dockerfile docker-compose.yml
   ```
   - プロジェクトルートに `Dockerfile` と `docker-compose.yml` のテンプレートを配置
6. **ディレクトリ構成確認**
   ```text
   myapp/
   ├── Dockerfile
   ├── docker-compose.yml
   ├── backend/
   └── frontend/
   ```
7. **初回ビルド・起動**
   ```bash
   docker-compose up --build
   ```

### 1. 研修の目的・前提

- **目的**: JavaScript が実際のアプリケーションでどう使われているかを理解する
- **前提**:
  - 生徒は JS の基礎を習得済み
  - バックエンド: Rails 7.2 (Sprockets)
  - フロントエンド: Rspack (モジュールバンドラー)
  - Docker 上で一つのイメージに Rails＋Rspack を統合

---

### 2. プロジェクト構成例

```
myapp/
├── Dockerfile
├── docker-compose.yml
├── backend/
│   ├── Gemfile
│   ├── config/
│   ├── app/
│   │   ├── assets/
│   │   │   └── javascripts/
│   │   │       └── application.js    # Sprockets 用
│   │   ├── views/
│   │   │   └── layouts/
│   │   │       └── application.html.erb
│   │   └── ...(Rails MVC)...
│   └── ...(その他ファイル)...
└── frontend/
    ├── package.json
    ├── tsconfig.json
    ├── .babelrc
    ├── rspack.config.js
    └── src/
        ├── index.js             # Rspack エントリ
        ├── moduleA.js
        ├── moduleB.js
        ├── index.ts             # TypeScript サンプル
        ├── App.tsx              # React サンプル
        ├── styles.css
        └── logo.png
```

---

### 3. Docker 環境構築

**Dockerfile (ubuntu:latest + Rails + Node)**

```dockerfile
FROM ubuntu:latest
RUN apt-get update && \
    apt-get install -y curl gnupg2 build-essential libpq-dev nodejs npm && gem install rails -v 7.2.0
WORKDIR /myapp

# Backend (Rails)
COPY backend/Gemfile* backend/
RUN bundle install --gemfile=backend/Gemfile

# Frontend (Rspack)
COPY frontend/package.json frontend/.babelrc frontend/tsconfig.json frontend/rspack.config.js frontend/
RUN npm install --prefix frontend
# Rspack でビルド (ステージング・本番向け)
RUN npm run build --prefix frontend

# 残りのソースコピー
COPY . .

# DB 作成・マイグレーション・サーバ起動
CMD ["bash", "-lc", "cd backend && rails db:create db:migrate && rails server -b 0.0.0.0"]
```

**docker-compose.yml**

```yaml
version: '3.8'
services:
  web:
    build: .
    ports:
      - "3000:3000"
    volumes:
      - ./backend:/myapp/backend
      - ./frontend:/myapp/frontend
```

---

### 4. ステップ 1: Sprockets でのバニラ JS

1. **app/assets/javascripts/application.js**
   ```js
   //= require hello
   ```
2. **app/assets/javascripts/hello.js**
   ```js
   document.addEventListener('DOMContentLoaded', () => {
     const btn = document.getElementById('hello-btn');
     btn.addEventListener('click', () => {
       alert('Hello, Rails + Vanilla JS!');
     });
   });
   ```
3. **app/views/layouts/application.html.erb** にボタンを追加
   ```erb
   <body>
     <button id="hello-btn">Click me</button>
     <%= javascript_include_tag 'application', 'data-turbolinks-track': 'reload' %>
     <%= stylesheet_link_tag 'application', 'data-turbolinks-track': 'reload' %>
   </body>
   ```
4. `docker-compose up` で http://localhost:3000 にアクセスし、ボタン押下を確認

---

### 5. ステップ 2: Rspack によるモジュールバンドリング

#### (a) import/export の基礎

- **frontend/src/moduleA.js**
  ```js
  export function greet(name) {
    return `Hello, ${name}!`;
  }
  ```
- **frontend/src/moduleB.js**
  ```js
  import { greet } from './moduleA';
  console.log(greet('Rails')); // Hello, Rails!
  ```
- **frontend/src/index.js**
  ```js
  import './moduleB';
  ```

#### (b) 外部パッケージの import

```bash
npm install lodash --save
```

- **frontend/src/index.js** に:
  ```js
  import { shuffle } from 'lodash';
  console.log(shuffle([1,2,3,4]));
  ```

Rails のレイアウトに以下を追加:

```erb
<%= javascript_include_tag '/packs/bundle.js', 'data-turbolinks-track': 'reload' %>
```

---

### 6. ステップ 3: トランスパイル(Typescript + Babel)

#### (a) TypeScript の例

- **frontend/src/index.ts**
  ```ts
  const message: string = 'TypeScript in Rails!';
  console.log(message);
  ```

#### (b) CSS & 画像のバンドル

- **frontend/src/styles.css**
  ```css
  .logo { width: 200px; }
  ```
- **frontend/src/index.js** に:
  ```js
  import './styles.css';
  import logo from './logo.png';
  document.body.innerHTML += `<img src='${logo}' class='logo'/>`;
  ```

#### (c) React(JSX) の例

- **frontend/src/App.tsx**
  ```tsx
  import React from 'react';
  export const App = () => <h1>Hello from React!</h1>;
  ```
- **frontend/src/index.tsx**
  ```tsx
  import React from 'react';
  import { createRoot } from 'react-dom/client';
  import { App } from './App';

  const root = createRoot(document.getElementById('root'));
  root.render(<App />);
  ```

ビュー側に `<div id="root"></div>` を配置し、bundle.js を読み込む

---

### 7. 実行と確認

```bash
# 初回ビルド
docker-compose up --build
# Rails サーバ起動 (port:3000)
```

http://localhost:3000 で各ステップを確認

---

### 8. FAQ / よくあるつまずき

- **ボタンが動かない**: Sprockets と Rspack の読み込み順序に注意
- **TypeScript が読み込まれない**: tsconfig.json の include パスを確認
- **画像が表示されない**: `asset/resource` の出力先と publicPath を合わせる

