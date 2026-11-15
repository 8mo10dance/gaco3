# 演習 #1：インスタンスプロファイルの関連付け忘れ

実 AWS に課金対象のリソースを作成します。
IAM ロールとインスタンスプロファイルは存在しますが、EC2 には関連付けません。

## 構築

Terraform、AWS CLI、Docker buildx を使用します。AWS の `default` プロファイル、
東京リージョン、許可アカウントは `provider.tf` で指定しています。
Amazon Linux 2023 の AMI は `tf01/` と同じものを使用します。

このディレクトリで実行してください。SSH 公開鍵は既定で
`./keys/floci_key.pub` を使用します。

```bash
terraform init
terraform apply
bash push.sh
```

別の鍵を使う場合は `-var='ssh_public_key_path=/path/to/key.pub'` も指定します。
ECR イメージを push する前でも、初回起動は認証情報不足の段階で失敗します。

## 調査

EC2 コンソールで演習用インスタンスの ID とパブリック IP を確認し、以下のプレースホルダーを置き換えてください。

```bash
ssh -i ./keys/floci_key ec2-user@<EC2のパブリックIP>
sudo cat /var/log/cloud-init-output.log
aws sts get-caller-identity
```

Docker のインストール完了後、ECR ログイン時の `Unable to locate credentials` を確認します。
ローカルの管理用シェルから関連付けを確認します。

```bash
aws --profile default --region ap-northeast-1 ec2 describe-instances \
  --instance-ids <EC2のインスタンスID> \
  --query 'Reservations[].Instances[].IamInstanceProfile'
```

空の結果が期待値です。IAM ロールには ECR 読み取りポリシーが存在します。

## AWS コンソールで修正

1. EC2 コンソールで演習用インスタンスを選択します。
2. 「アクション」→「セキュリティ」→「IAM ロールを変更」を開きます。
3. `exercise-01-ec2-profile` に対応する IAM ロールを選び、更新します。
4. 認証情報の反映を待ち、SSH 接続先で次を実行します。

```bash
aws sts get-caller-identity
ECR_URL=347408264688.dkr.ecr.ap-northeast-1.amazonaws.com/exercise-01-nginx
aws ecr get-login-password --region ap-northeast-1 |
  sudo docker login --username AWS --password-stdin "${ECR_URL%%/*}"
sudo docker pull "$ECR_URL:latest"
sudo docker run -d --name nginx --restart unless-stopped -p 80:80 "$ECR_URL:latest"
sudo docker ps
curl http://localhost/
```

STS の ARN が `assumed-role/exercise-01-ec2-role/…` であることを確認します。
ローカルからも `curl http://<EC2のパブリックIP>/` で確認できます。
user_data は自動再実行されないため、ECR ログイン以降の処理を手動で再実行します。
コンソール修正後は Terraform に差分が生じます。復旧確認中は再 apply しないでください。

## 削除

ECR 内のイメージを削除してから destroy します。

```bash
aws --profile default --region ap-northeast-1 ecr batch-delete-image \
  --repository-name exercise-01-nginx --image-ids imageTag=latest
terraform destroy
```

追加で push したタグや未タグのイメージがあれば、それらも削除してください。
