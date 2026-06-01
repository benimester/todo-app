#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive
apt-get update -y && apt-get install -y curl

curl -sfL https://get.k3s.io | K3S_URL=https://${master_ip}:6443 K3S_TOKEN=${token} sh -
