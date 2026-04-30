#!/usr/bin/env bash
set -euo pipefail

sudo docker pull getnao/nao:latest
sudo docker stop nao 2>/dev/null || true
sudo docker rm nao 2>/dev/null || true
sudo docker run -d \
  --name nao \
  --env-file /etc/nao/.env \
  -p 80:5005 \
  --restart always \
  getnao/nao:latest

sleep 10
curl -sf http://localhost/health || curl -sf http://localhost

PUBLIC_IP="$(curl -s https://checkip.amazonaws.com)"
echo "Done! Nao is running at http://${PUBLIC_IP}"
