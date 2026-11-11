#!/bin/bash

set -auo pipefail

dnf update -y
dnf install -y docker

systemctl enable --now docker

REGION="${region}"
ECR_URL="${ecr_url}"
ECR_REGISTRY="${ecr_registry}"

aws ecr get-login-password --region "$REGION" |
  docker login --username AWS --password-stdin "$ECR_REGISTRY"

docker pull "$ECR_URL:latest"

docker run -d --name nginx --restart unless-stopped -p 80:80 "$ECR_URL:latest"
