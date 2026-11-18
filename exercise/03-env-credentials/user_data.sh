#!/bin/bash
set -euo pipefail

dnf install -y docker
systemctl enable --now docker
mkdir -p /opt/myapp
cat > /opt/myapp/deploy.env <<'ENV'
export APP_ENV=production
export AWS_DEFAULT_REGION=ap-northeast-1
export AWS_ACCESS_KEY_ID=AKIAEXAMPLEOLDKEY
export AWS_SECRET_ACCESS_KEY=EXAMPLE_OLD_SECRET_KEY
ENV
chmod 600 /opt/myapp/deploy.env
source /opt/myapp/deploy.env

aws ecr get-login-password --region '${region}' |
  docker login --username AWS --password-stdin '${ecr_registry}'
docker pull '${ecr_url}:latest'
docker rm -f nginx 2>/dev/null || true
docker run -d --name nginx --restart unless-stopped -p 80:80 '${ecr_url}:latest'
