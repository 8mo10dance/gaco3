#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
ECR_URL=$(terraform output -raw ecr_repository_url)
ECR_REGISTRY=${ECR_URL%%/*}
aws --profile default --region ap-northeast-1 ecr get-login-password |
  docker login --username AWS --password-stdin "$ECR_REGISTRY"
docker buildx build --platform linux/amd64 -t "$ECR_URL:latest" --push .
