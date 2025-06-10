#!/bin/bash

# === THÔNG SỐ TÙY CHỈNH ===
DOMAIN_ADGUARD="adg.example.com"         # ⚠️ Đổi thành domain bạn muốn trỏ về AdGuard
DOMAIN_PORTAINER="portainer.example.com" # ⚠️ Đổi thành domain cho Portainer
INSTALL_DIR="/opt/adguard"
ADGUARD_PORT=8080
# URL đến file whitelist của bạn trên GitHub (dạng raw)
WHITELIST_URL="https://raw.githubusercontent.com/tuanmuvn/adguard_docker_vps/refs/heads/main/whitelist_ip.txt" # ⚠️ ĐỔI THÀNH URL CỦA BẠN
# === CÀI ĐẶT DOCKER & DOCKER COMPOSE ===
echo "👉 Đang cài Docker..."
apt update && apt install -y ca-certificates curl gnupg lsb-release

install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker.gpg

echo   "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg]   https://download.docker.com/linux/debian $(lsb_release -cs) stable"   > /etc/apt/sources.list.d/docker.list

apt update && apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

systemctl enable docker
systemctl start docker

# === TẠO CẤU TRÚC THƯ MỤC ===
echo "📁 Tạo thư mục: $INSTALL_DIR"
mkdir -p $INSTALL_DIR/{adguard/conf,adguard/work,caddy_data,caddy_config}
cd $INSTALL_DIR

# === TẠO docker-compose.yml ===
echo "📝 Tạo docker-compose.yml..."
cat <<EOF > docker-compose.yml
version: "3.8"

services:
  adguardhome:
    image: adguard/adguardhome
    container_name: adguardhome
    restart: unless-stopped
    ports:
      - "53:53/tcp"
      - "53:53/udp"
      - "67:67/udp"
      - "${ADGUARD_PORT}:80/tcp"
    volumes:
      - ./adguard/work:/opt/adguardhome/work
      - ./adguard/conf:/opt/adguardhome/conf

  caddy:
    image: caddy:latest
    container_name: caddy
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - ./caddy_data:/data
      - ./caddy_config:/config

  portainer:
    image: portainer/portainer-ce:latest
    container_name: portainer
    restart: unless-stopped
    ports:
      - "9000:9000"
      - "8000:8000"
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - portainer_data:/data

volumes:
  portainer_data:
EOF

# === TẠO Caddyfile ===
echo "📝 Tạo Caddyfile..."
cat <<EOF > Caddyfile
$DOMAIN_ADGUARD {
    reverse_proxy adguardhome:80
}

$DOMAIN_PORTAINER {
    reverse_proxy portainer:9000
}
EOF

# === KHỞI ĐỘNG DỊCH VỤ ===
echo "🚀 Đang khởi động các container..."
docker compose up -d

# <<< PHẦN CẬP NHẬT: CẤU HÌNH TƯỜNG LỬA UFW VỚI FILE TỪ GITHUB >>>
echo ""
echo "🔥 Đang cấu hình Firewall (UFW) với IP Whitelist từ GitHub..."

# Cài đặt UFW nếu chưa có
apt install -y ufw

# Tải file whitelist từ URL được cung cấp
echo "🌐 Đang tải whitelist từ: $WHITELIST_URL"
if ! curl -fsSL "$WHITELIST_URL" -o whitelist_ip.txt; then
    echo "❌ LỖI: Không thể tải file whitelist từ URL. Vui lòng kiểm tra lại URL và kết nối mạng."
    echo "Script sẽ dừng lại để đảm bảo an toàn."
    exit 1
fi
echo "✅ Đã tải thành công file whitelist_ip.txt."

# Đặt lại UFW về trạng thái mặc định để đảm bảo cấu hình sạch
ufw --force reset

# 1. Đặt chính sách mặc định: Chặn tất cả kết nối đến, cho phép tất cả kết nối đi.
ufw default deny incoming
ufw default allow outgoing

# 2. Mở các cổng CÔNG KHAI cần thiết cho Caddy và Let's Encrypt
echo "ALLOWING Caddy ports (80, 443) for Let's Encrypt"
ufw allow 80/tcp
ufw allow 443/tcp

# 3. Cho phép tất cả các kết nối từ các IP trong whitelist đã tải về
echo "PROCESSING WHITELIST from whitelist_ip.txt..."
# Kiểm tra xem file có tồn tại và có nội dung không
if [ -s whitelist_ip.txt ]; then
    while read -r ip; do
      # Bỏ qua các dòng trống và dòng comment
      if [[ -n "$ip" && ! "$ip" =~ ^# ]]; then
        echo "  ALLOWING all traffic from: $ip"
        ufw allow from "$ip"
      fi
    done < whitelist_ip.txt
else
    echo "⚠️ CẢNH BÁO: File whitelist_ip.txt rỗng hoặc không tồn tại. Sẽ không có IP nào được thêm vào whitelist."
    echo "⚠️ BẠN CÓ THỂ BỊ KHÓA TRUY CẬP SSH. Script sẽ tạm dừng 10 giây để bạn có thể hủy (Ctrl+C)."
    sleep 10
fi

# Kích hoạt UFW mà không cần hỏi
yes | ufw enable

echo "✅ Firewall đã được kích hoạt. Kiểm tra trạng thái:"
ufw status verbose
# <<< KẾT THÚC PHẦN CẬP NHẬT >>>


# === HOÀN TẤT ===
echo ""
echo "✅ Cài đặt hoàn tất!"
echo "➡️ Truy cập cấu hình AdGuard ban đầu tại: http://<IP-VPS>:${ADGUARD_PORT}"
echo "➡️ Sau khi cấu hình xong, dùng HTTPS tại:"
echo "   - AdGuard: https://$DOMAIN_ADGUARD"
echo "   - Portainer: https://$DOMAIN_PORTAINER"
echo ""
echo "🔐 Caddy sẽ tự cấp chứng chỉ SSL miễn phí từ Let's Encrypt và tự gia hạn."
echo "🛡️ Firewall UFW đang hoạt động, chỉ cho phép truy cập từ các IP trong whitelist đã tải về từ GitHub."
