#!/bin/bash
set -e

IP_WHITELIST_URL="https://raw.githubusercontent.com/tuanmuvn/adguard_docker_vps/refs/heads/main/whitelist_ip.txt"
DOCKER_APP_DIR="/opt/vps_stack"

echo "===== Cập nhật hệ thống ====="
apt-get update && apt-get upgrade -y
apt-get install -y curl wget apt-transport-https ca-certificates software-properties-common gnupg ufw

echo "===== Cài đặt Docker ====="
if ! command -v docker &> /dev/null; then
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    if [ "$SUDO_USER" ]; then
        usermod -aG docker "$SUDO_USER"
    fi
fi

echo "===== Cài đặt Docker Compose Plugin ====="
apt-get install -y docker-compose-plugin

echo "===== Tạo thư mục ứng dụng ====="
mkdir -p $DOCKER_APP_DIR/{npm-data,npm-letsencrypt,adguard-work,adguard-conf,portainer-data}
cat > $DOCKER_APP_DIR/docker-compose.yml <<EOF
version: '3.8'
services:
  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    volumes:
      - /etc/localtime:/etc/localtime:ro
      - /var/run/docker.sock:/var/run/docker.sock
      - ./portainer-data:/data
    ports:
      - "9443:9443"
      - "9000:9000"
      - "8000:8000"

  nginx-proxy-manager:
    image: 'jc21/nginx-proxy-manager:latest'
    container_name: nginx-proxy-manager
    restart: unless-stopped
    ports:
      - '80:80'
      - '443:443'
      - '81:81'
    volumes:
      - ./npm-data:/data
      - ./npm-letsencrypt:/etc/letsencrypt

  adguardhome:
    image: adguard/adguardhome:latest
    container_name: adguardhome
    restart: unless-stopped
    ports:
      - "53:53/tcp"
      - "53:53/udp"
      - "67:67/udp"
      - "68:68/udp"
      - "3000:3000/tcp"
      - "853:853/tcp"
    volumes:
      - ./adguard-work:/opt/adguardhome/work
      - ./adguard-conf:/opt/adguardhome/conf
EOF

echo "===== Khởi chạy container ====="
cd $DOCKER_APP_DIR
docker compose up -d

echo "===== Cấu hình UFW ====="
ufw --force reset
ufw default deny incoming
ufw default allow outgoing

if wget -qO- "$IP_WHITELIST_URL" | grep -vE '^\s*#|^\s*$' > /tmp/allowed_ips.txt; then
    while IFS= read -r ip; do
        ufw allow from "$ip" to any port 22 comment 'SSH'
        ufw allow from "$ip" to any port 9443 proto tcp
        ufw allow from "$ip" to any port 9000 proto tcp
        ufw allow from "$ip" to any port 8000 proto tcp
        ufw allow from "$ip" to any port 81 proto tcp
        ufw allow from "$ip" to any port 443 proto tcp
        ufw allow from "$ip" to any port 3000 proto tcp
        ufw allow from "$ip" to any port 53
    done < /tmp/allowed_ips.txt
    rm /tmp/allowed_ips.txt
else
    echo "Không thể tải whitelist từ $IP_WHITELIST_URL"
    exit 1
fi

ufw --force enable
ufw status verbose

echo "===== Cài đặt hoàn tất ====="
echo "Portainer: https://<IP_VPS>:9443"
echo "Nginx Proxy Manager: http://<IP_VPS>:81"
echo "AdGuard Home: http://<IP_VPS>:3000"
