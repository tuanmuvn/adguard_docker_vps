#!/bin/bash
set -e

# ============================
# 1. Cập nhật hệ thống
# ============================
echo "=== Cập nhật hệ thống ==="
apt update && apt upgrade -y

# ============================
# 2. Cài Docker & Docker Compose
# ============================
echo "=== Cài Docker và Docker Compose ==="
apt install -y apt-transport-https ca-certificates curl gnupg lsb-release ufw

# Thêm repo Docker
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /usr/share/keyrings/docker.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker.gpg] \
  https://download.docker.com/linux/debian \
  $(lsb_release -cs) stable" \
  | tee /etc/apt/sources.list.d/docker.list > /dev/null

apt update
apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# Bật Docker
systemctl enable docker
systemctl start docker

# ============================
# 3. Tạo docker-compose.yml
# ============================
echo "=== Tạo docker-compose.yml ==="
mkdir -p /opt/docker-apps
cd /opt/docker-apps

cat > docker-compose.yml << 'EOF'
version: "3.8"

services:
  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    restart: unless-stopped
    security_opt:
      - no-new-privileges:true
    ports:
      - "9000:9000"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data

  npm:
    image: jc21/nginx-proxy-manager:latest
    container_name: nginx-proxy-manager
    restart: unless-stopped
    ports:
      - "80:80"
      - "81:81"
      - "443:443"
    volumes:
      - npm_data:/data
      - npm_letsencrypt:/etc/letsencrypt

  adguardhome:
    image: adguard/adguardhome:latest
    container_name: adguardhome
    restart: unless-stopped
    ports:
      - "3000:3000"
      - "53:53/tcp"
      - "53:53/udp"
      - "67:67/udp"
      - "68:68/tcp"
      - "68:68/udp"
      - "80:80/tcp"
    volumes:
      - adguard_conf:/opt/adguardhome/conf
      - adguard_work:/opt/adguardhome/work

volumes:
  portainer_data:
  npm_data:
  npm_letsencrypt:
  adguard_conf:
  adguard_work:
EOF

# ============================
# 4. Cấu hình UFW
# ============================
echo "=== Cấu hình UFW Firewall ==="
ufw --force reset
ufw default deny incoming
ufw default allow outgoing

# Lấy danh sách IP tin cậy
TRUSTED_IPS=$(curl -s https://raw.githubusercontent.com/tuanmuvn/adguard_docker_vps/refs/heads/main/whitelist_ip.txt)

# Thêm IP tin cậy
for ip in $TRUSTED_IPS; do
    ufw allow from $ip
done

# Cho phép SSH từ IP tin cậy
for ip in $TRUSTED_IPS; do
    ufw allow from $ip to any port 22
done

# Mở port cho dịch vụ từ IP tin cậy
for ip in $TRUSTED_IPS; do
    ufw allow from $ip to any port 9000 proto tcp
    ufw allow from $ip to any port 81 proto tcp
    ufw allow from $ip to any port 443 proto tcp
    ufw allow from $ip to any port 3000 proto tcp
done

ufw --force enable

# ============================
# 5. Khởi động Docker Compose
# ============================
echo "=== Khởi động Docker Compose ==="
docker compose up -d

echo "=== Hoàn tất cài đặt ==="
echo "Portainer CE: http://<IP-VPS>:9000"
echo "Nginx Proxy Manager: http://<IP-VPS>:81"
echo "AdGuard Home: http://<IP-VPS>:3000"
