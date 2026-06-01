#!/bin/bash
set -e

export DEBIAN_FRONTEND=noninteractive
apt-get update -y
apt-get install -y nginx

cat << 'NYN' > /etc/nginx/sites-available/default
upstream k3s_nodes {
%{ for ip in node_ips ~}
    server ${ip}:30080;
%{ endfor ~}
}

server {
    listen 80 default_server;
    listen [::]:80 default_server;

    client_max_body_size 20M;

    location / {
        proxy_pass http://k3s_nodes;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_connect_timeout 10s;
        proxy_read_timeout    60s;
    }
}
NYN

systemctl enable nginx
systemctl restart nginx