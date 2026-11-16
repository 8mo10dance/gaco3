#!/bin/bash
set -euo pipefail

dnf install -y docker
systemctl enable --now docker
aws ecr get-login-password --region '${region}' |
  docker login --username AWS --password-stdin '${ecr_registry}'
docker pull '${ecr_url}:latest'
docker rm -f nginx 2>/dev/null || true
docker run -d --name nginx --restart unless-stopped -p 80:80 '${ecr_url}:latest'
