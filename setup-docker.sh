#!/bin/bash

set -e

echo "===== Cập nhật hệ thống ====="
apt update && apt upgrade -y

echo "===== Cài đặt Docker ====="
apt install -y curl apt-transport-https ca-certificates gnupg lsb-release
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

echo "===== Cài đặt Portainer CE ====="
docker volume create portainer_data
docker run -d \
  -p 8000:8000 \
  -p 9443:9443 \
  --name=portainer \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v portainer_data:/data \
  portainer/portainer-ce:latest

echo "===== Cài đặt Nginx Proxy Manager ====="
mkdir -p /root/npm
cat <<EOF > /root/npm/docker-compose.yml
version: '3'
services:
  app:
    image: jc21/nginx-proxy-manager:latest
    restart: unless-stopped
    ports:
      - "80:80"
      - "81:81"
      - "443:443"
    volumes:
      - ./data:/data
      - ./letsencrypt:/etc/letsencrypt
EOF
docker compose -f /root/npm/docker-compose.yml up -d

echo "===== Cài đặt AdGuard Home ====="
mkdir -p /root/adguard
cat <<EOF > /root/adguard/docker-compose.yml
version: '3'
services:
  adguardhome:
    image: adguard/adguardhome:latest
    container_name: adguardhome
    restart: unless-stopped
    ports:
      - "53:53/tcp"
      - "53:53/udp"
      - "3000:3000/tcp"
    volumes:
      - ./work:/opt/adguardhome/work
      - ./conf:/opt/adguardhome/conf
EOF
docker compose -f /root/adguard/docker-compose.yml up -d

echo "===== Hoàn tất cài đặt ====="
echo "Portainer CE: https://<IP_VPS>:9443"
echo "Nginx Proxy Manager: http://<IP_VPS>:81"
echo "AdGuard Home: http://<IP_VPS>:3000"
