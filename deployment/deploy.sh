#!/usr/bin/env bash
set -euo pipefail

: "${NAO_METADATA_URL:?NAO_METADATA_URL is required}"
: "${OPENAI_API_KEY:?OPENAI_API_KEY is required}"
: "${GITHUB_TOKEN:?GITHUB_TOKEN is required}"
: "${GITHUB_REPO:?GITHUB_REPO is required}"
: "${DATA_SOURCE_HOST:?DATA_SOURCE_HOST is required}"
: "${DATA_SOURCE_DB_NAME:?DATA_SOURCE_DB_NAME is required}"
: "${DATA_SOURCE_USER:?DATA_SOURCE_USER is required}"
: "${DATA_SOURCE_PASSWORD:?DATA_SOURCE_PASSWORD is required}"

BETTER_AUTH_SECRET="$(openssl rand -hex 32)"
PUBLIC_IP="$(curl -s https://checkip.amazonaws.com)"

if ! command -v docker &>/dev/null; then
  echo "Installing Docker..."
  sudo apt-get update -q
  sudo apt-get install -y -q docker.io
  sudo systemctl enable --now docker
  sudo usermod -aG docker ubuntu
fi

echo "Writing /etc/nao/.env..."
sudo mkdir -p /etc/nao
sudo tee /etc/nao/.env > /dev/null <<EOF
DB_URI=${NAO_METADATA_URL}
OPENAI_API_KEY=${OPENAI_API_KEY}
DATA_SOURCE_HOST=${DATA_SOURCE_HOST}
DATA_SOURCE_DB_NAME=${DATA_SOURCE_DB_NAME}
DATA_SOURCE_USER=${DATA_SOURCE_USER}
DATA_SOURCE_PASSWORD=${DATA_SOURCE_PASSWORD}
NAO_CONTEXT_SOURCE=git
NAO_CONTEXT_GIT_URL=${GITHUB_REPO}
NAO_CONTEXT_GIT_TOKEN=${GITHUB_TOKEN}
NAO_DEFAULT_PROJECT_PATH=/app/project
BETTER_AUTH_URL=http://${PUBLIC_IP}
BETTER_AUTH_SECRET=${BETTER_AUTH_SECRET}
EOF
sudo chmod 600 /etc/nao/.env

echo "Starting Nao..."
sudo docker pull getnao/nao:latest
sudo docker stop nao 2>/dev/null || true
sudo docker rm nao 2>/dev/null || true
sudo docker run -d \
  --name nao \
  --env-file /etc/nao/.env \
  -p 80:5005 \
  --restart always \
  getnao/nao:latest

echo "Waiting for Nao to start..."
sleep 10
curl -sf http://localhost/health || curl -sf http://localhost

echo ""
echo "Done! Nao is running at http://${PUBLIC_IP}"
