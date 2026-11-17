# 演習 #2：ECR 認証に必要な IAM 権限の不足

実 AWS に課金対象のリソースを作成します。
EC2 のインスタンスプロファイルは設定済みですが、ロールに `ecr:GetAuthorizationToken` がありません。

## 構築

Terraform、AWS CLI、Docker buildx を使用します。ローカル端末のこのディレクトリで実行してください。
`default` プロファイル、東京リージョン、許可アカウントは `provider.tf` で指定しています。
SSH 鍵は演習 #1 から `keys/` にコピー済みで、Git 管理対象外です。
別の公開鍵は `-var='ssh_public_key_path=/path/to/key.pub'` で指定できます。

```bash
terraform init
terraform apply
bash push.sh
```

イメージ push 前でも、初回起動は ECR 認証の権限不足で失敗します。

## 調査

EC2 コンソールでインスタンス ID とパブリック IP を確認します。
ローカル端末から接続してください。

```bash
ssh -i ./keys/floci_key ec2-user@<EC2のパブリックIP>
```

以下は **EC2 上** で実行します。`--profile default` は指定しません。

```bash
sudo cat /var/log/cloud-init-output.log
aws sts get-caller-identity
aws ecr get-login-password --region ap-northeast-1
```

STS は `assumed-role/exercise-02-ec2-role/…` を返し、ECR は
`GetAuthorizationToken` に対する `AccessDeniedException` となるのが期待値です。

ローカル端末から初期ポリシーを確認できます。

```bash
aws --profile default iam get-role-policy \
  --role-name exercise-02-ec2-role --policy-name exercise-02-ecr-read
```

## AWS コンソールで修正

IAM コンソールで `exercise-02-ec2-role` のインラインポリシー
`exercise-02-ecr-read` を編集し、既存 Statement を残して次を追加します。

```json
{
  "Effect": "Allow",
  "Action": "ecr:GetAuthorizationToken",
  "Resource": "*"
}
```

### Statement を分ける理由

同じ Statement 内の `Action` には、共通の `Resource` が適用されます。
既存 Statement はイメージ取得の権限を `exercise-02-nginx` のリポジトリ ARN に限定しています。
一方、`ecr:GetAuthorizationToken` はリソース単位の指定に対応しておらず、`Resource: "*"` が必要です。
そのため、既存 Statement の `Action` に追記するだけでは、トークン取得は許可されません。

既存 Statement の `Resource` も `"*"` に変更すればまとめられますが、イメージ取得の権限まで全リポジトリに広がります。
対象リポジトリへの制限を維持するため、同じポリシー内で Statement を分けます。
詳細は [AWS の ECR 権限一覧](https://docs.aws.amazon.com/service-authorization/latest/reference/list_ecr.html) を参照してください。

### 修正後の動作確認

変更の伝播を待ちます。EC2 再起動は不要ですが、失敗した `user_data` は自動再実行されません。
ローカルで `bash push.sh` を実行済みであることを確認し、**EC2 上** で以下を実行します。

```bash
ECR_URL=347408264688.dkr.ecr.ap-northeast-1.amazonaws.com/exercise-02-nginx
aws ecr get-login-password --region ap-northeast-1 |
  sudo docker login --username AWS --password-stdin "${ECR_URL%%/*}"
sudo docker pull "$ECR_URL:latest"
sudo docker rm -f nginx 2>/dev/null || true
sudo docker run -d --name nginx --restart unless-stopped -p 80:80 "$ECR_URL:latest"
sudo docker ps
curl http://localhost/
```

ローカル端末でも `curl http://<EC2のパブリックIP>/` で演習 #2 のページを確認します。
コンソール修正は Terraform に差分を生じさせます。復旧確認中は再 apply しないでください。

## 削除

ローカル端末で実行します。

```bash
aws --profile default --region ap-northeast-1 ecr batch-delete-image \
  --repository-name exercise-02-nginx --image-ids imageTag=latest
terraform destroy
```

追加タグや未タグのイメージがある場合は、それらも削除してください。
