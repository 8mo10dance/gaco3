# Docker on WSL2 トラブルシューティング

## 問題1: Docker API への接続権限エラー

```
permission denied while trying to connect to the docker API at unix:///var/run/docker.sock
```

### 原因
ユーザーが `docker` グループに追加されていない。

### 解決方法

```bash
# docker グループに追加
sudo usermod -aG docker $USER

# ログアウト/再ログインせずにすぐ反映
newgrp docker

# 確認
groups | grep docker
```

Docker デーモンが起動しているか確認：

```bash
sudo systemctl status docker
sudo systemctl start docker  # 止まっていた場合
```

---

## 問題2: クレデンシャルヘルパーのエラー

```
error getting credentials - err: fork/exec /usr/bin/docker-credential-desktop.exe: exec format error
```

### 原因
`~/.docker/config.json` に Windows 用のクレデンシャルヘルパー (`desktop.exe`) が指定されたまま残っている。

### 確認

```bash
cat ~/.docker/config.json
# "credsStore": "desktop.exe" があれば該当
```

### 解決方法

```bash
# バックアップ
cp ~/.docker/config.json ~/.docker/config.json.bak

# config.json をリセット
cat > ~/.docker/config.json << 'EOF'
{}
EOF
```

---

## なぜ混入するのか（WSL2 の場合）

Docker Desktop for Windows は WSL2 統合機能により、Windows 側の設定を WSL2 のホームディレクトリに書き込む。その際に `docker-credential-desktop.exe` のような Windows バイナリのパスがそのまま `~/.docker/config.json` に入ってしまう。

### WSL2 での選択肢

**① Docker Desktop の WSL2 統合をそのまま使う（手軽）**

`config.json` を `{}` にリセットすれば大抵は動く。

**② WSL2 内に Docker Engine を直接インストールする（安定）**

Docker Desktop を経由せず Linux ネイティブの Docker を使う方法。パフォーマンスも良く、混入問題も発生しない。

```bash
sudo apt install docker.io
sudo usermod -aG docker $USER
```
