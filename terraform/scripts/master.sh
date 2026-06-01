#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive
apt-get update -y && apt-get install -y curl unzip

if [ ! -f /swapfile ]; then
  fallocate -l 2G /swapfile
  chmod 600 /swapfile
  mkswap /swapfile
  swapon /swapfile
  echo '/swapfile none swap sw 0 0' >> /etc/fstab
fi

curl -sfL https://get.k3s.io | K3S_TOKEN="${token}" sh -s - server \
  --tls-san="127.0.0.1" \
  --tls-san="localhost" \
  --write-kubeconfig-mode "644" \
  --disable traefik \
  --disable metrics-server


# Upload kubeconfig to SM
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

unzip awscliv2.zip
sudo ./aws/install

while [ ! -f /etc/rancher/k3s/k3s.yaml ]; do
  sleep 2
done

aws secretsmanager put-secret-value \
  --secret-id "${secret_id}" \
  --secret-string "$(cat /etc/rancher/k3s/k3s.yaml)" \
  --region "${region}"
