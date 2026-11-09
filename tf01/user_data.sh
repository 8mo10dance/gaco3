#!/bin/bash

set -auo pipefail

dnf update -y
dnf install -y nginx

systemctl enable --now nginx
