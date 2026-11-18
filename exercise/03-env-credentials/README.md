# 演習 #3：環境変数による認証情報の上書き

実 AWS に課金対象のリソースを作成します。EC2 のロールと ECR 読み取り権限は設定済みですが、
user_data が読み込む架空の固定キーによって認証に失敗します。

## 構築

Terraform、AWS CLI、Docker buildx を使用します。このディレクトリで実行してください。
default プロファイル、東京リージョン、許可アカウントは provider.tf で指定しています。
SSH 鍵は演習 #1 から keys/ にコピー済みで、Git 管理対象外です。
別の公開鍵は -var='ssh_public_key_path=/path/to/key.pub' で指定できます。

```bash
terraform init
terraform apply
bash push.sh
```

イメージ push 前でも、初回起動は ECR 認証で失敗します。

## 調査

EC2 コンソールでパブリック IP を確認し、ローカルから接続します。

```bash
ssh -i ./keys/floci_key ec2-user@<EC2のパブリックIP>
```

以下は EC2 上で実行します。AWS CLI に --profile default は指定しません。

```bash
sudo cat /var/log/cloud-init-output.log
aws configure list
aws sts get-caller-identity
aws ecr get-login-password --region ap-northeast-1 |
  sudo docker login --username AWS --password-stdin 347408264688.dkr.ecr.ap-northeast-1.amazonaws.com
```

初回起動ログでは GetAuthorizationToken の無効な認証情報エラーが期待値です。
SSH では assumed-role/exercise-03-ec2-role/… が返り、ECR ログインが成功します。
SSH シェルは deploy.env を読み込んでいないためです。

次のサブシェルで user_data と同じ環境を再現します。終了後は元のシェルに戻ります。

```bash
sudo bash -c '
  source /opt/myapp/deploy.env
  aws configure list
  aws sts get-caller-identity
  aws ecr get-login-password --region ap-northeast-1
'
```

configure list の認証情報の取得元が env となり、STS と ECR が失敗することを確認します。
環境変数の認証情報はインスタンスプロファイルより優先されます。

## 修正と復旧

EC2 上で環境ファイルから固定キーを削除します。IAM の変更は不要です。

```bash
sudo sed -i '/^export AWS_ACCESS_KEY_ID=/d; /^export AWS_SECRET_ACCESS_KEY=/d; /^export AWS_SESSION_TOKEN=/d' /opt/myapp/deploy.env
sudo bash <<'ROOT'
set -euo pipefail
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN
source /opt/myapp/deploy.env
aws configure list
aws sts get-caller-identity
ECR_URL=347408264688.dkr.ecr.ap-northeast-1.amazonaws.com/exercise-03-nginx
aws ecr get-login-password --region ap-northeast-1 |
  docker login --username AWS --password-stdin "${ECR_URL%%/*}"
docker pull "$ECR_URL:latest"
docker rm -f nginx 2>/dev/null || true
docker run -d --name nginx --restart unless-stopped -p 80:80 "$ECR_URL:latest"
docker ps
curl http://localhost/
ROOT
```

ローカルで push.sh を実行済みであることが前提です。認証情報の取得元が iam-role、
ARN が assumed-role/exercise-03-ec2-role/… であることを確認します。
ローカルからも curl http://<EC2のパブリックIP>/ で演習 #3 のページを確認できます。

通常の user_data は自動再実行されません。この演習の user_data を丸ごと再実行すると
架空キー入りの deploy.env を再作成するため、復旧時は上記の処理だけを実行します。
EC2 を再作成すると初期の障害状態に戻ります。

## 削除

ローカル端末で実行します。

```bash
aws --profile default --region ap-northeast-1 ecr batch-delete-image \
  --repository-name exercise-03-nginx --image-ids imageTag=latest
terraform destroy
```

追加タグや未タグのイメージがあれば、それらも削除してください。
