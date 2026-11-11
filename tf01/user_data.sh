#!/bin/bash

set -auo pipefail

dnf update -y
dnf install -y docker

systemctl enable --now docker

docker run -d --name nginx --restart unless-stopped -p 80:80 nginx:alpine
