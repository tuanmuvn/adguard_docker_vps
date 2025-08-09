#!/bin/bash

#-----------------------------------------------------------------------------------
# Script tự động cài đặt Docker, Portainer, Nginx Proxy Manager, AdGuard Home
# và cấu hình tường lửa UFW trên Debian VPS.
#
# Yêu cầu: Chạy với quyền root hoặc sudo.
#-----------------------------------------------------------------------------------

set -e # Thoát ngay lập tức nếu có lỗi

# URL chứa danh sách IP tin cậy
IP_WHITELIST_URL="https://raw.githubusercontent.com/tuanmuvn/adguard_docker_vps/refs/heads/main/whitelist_ip.txt"

# Thư mục lưu trữ dữ liệu các ứng dụng Docker
DOCKER_APP_DIR="/opt/vps_stack"

# Bước 1: Cập nhật hệ thống và cài đặt các gói cần thiết
echo "===== Bước 1: Đang cập nhật hệ thống và cài đặt các gói cần thiết... ====="
apt-get update
apt-get upgrade -y
apt-get install -y curl wget apt-transport-https ca-certificates software-properties-common gnupg ufw

# Bước 2: Cài đặt Docker và Docker Compose
echo "===== Bước 2: Đang cài đặt Docker và Docker Compose... ====="
if ! [ -x "$(command -v docker)" ]; then
    echo "Docker chưa được cài đặt. Bắt đầu cài đặt..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    # Thêm người dùng hiện tại vào nhóm docker để chạy lệnh không cần sudo
    # Nếu đang chạy với quyền root, lệnh này sẽ không có tác dụng nhiều nhưng vẫn hữu ích
    usermod -aG docker $(logname)
else
    echo "Docker đã được cài đặt."
fi

# Cài đặt Docker Compose
if ! [ -x "$(command -v docker-compose)" ]; then
    echo "Docker Compose chưa được cài đặt. Bắt đầu cài đặt..."
    apt-get install -y docker-compose-v2
else
    echo "Docker Compose đã được cài đặt."
fi
echo "===== Docker và Docker Compose đã được cài đặt thành công. ====="

# Bước 3: Tạo thư mục và file docker-compose.yml cho các ứng dụng
echo "===== Bước 3: Đang tạo cấu trúc thư mục và file docker-compose.yml... ====="
mkdir -p $DOCKER_APP_DIR/npm-data
mkdir -p $DOCKER_APP_DIR/npm-letsencrypt
mkdir -p $DOCKER_APP_DIR/adguard-work
mkdir -p $DOCKER_APP_DIR/adguard-conf
mkdir -p $DOCKER_APP_DIR/portainer-data

# Tạo file docker-compose.yml
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
      - "3000:3000/tcp" # Giao diện web AdGuard
      - "853:853/tcp"  # DNS-over-TLS
    volumes:
      - ./adguard-work:/opt/adguardhome/work
      - ./adguard-conf:/opt/adguardhome/conf
EOF

echo "===== File docker-compose.yml đã được tạo tại $DOCKER_APP_DIR/docker-compose.yml ====="

# Bước 4: Khởi chạy các container
echo "===== Bước 4: Đang khởi chạy các container Docker... ====="
cd $DOCKER_APP_DIR
docker-compose up -d
echo "===== Các ứng dụng đã được khởi chạy. ====="

# Bước 5: Cấu hình tường lửa UFW
echo "===== Bước 5: Đang cấu hình tường lửa UFW... ====="
# Reset UFW về mặc định để tránh các quy tắc cũ
ufw --force reset

# Thiết lập quy tắc mặc định: từ chối mọi kết nối đến, cho phép mọi kết nối đi
ufw default deny incoming
ufw default allow outgoing

# Tải danh sách IP tin cậy
echo "Đang tải danh sách IP từ $IP_WHITELIST_URL..."
if wget -qO- "$IP_WHITELIST_URL" > /tmp/allowed_ips.txt; then
    # Lặp qua từng IP trong danh sách và thêm vào quy tắc allow của UFW
    echo "Đang thêm các IP tin cậy vào tường lửa..."
    while IFS= read -r ip; do
        if [ -n "$ip" ]; then
            ufw allow from "$ip" comment 'IP tin cay'
            echo "Đã cho phép IP: $ip"
        fi
    done < /tmp/allowed_ips.txt

    # Xóa file tạm
    rm /tmp/allowed_ips.txt
else
    echo "LỖI: Không thể tải danh sách IP. Vui lòng kiểm tra lại URL."
    # Bạn có thể quyết định dừng script ở đây nếu danh sách IP là bắt buộc
    # exit 1
fi

# Luôn cho phép kết nối SSH để tránh bị khóa ngoài
# GHI CHÚ: Quy tắc này sẽ được ghi đè nếu IP của bạn không có trong whitelist
# Để an toàn hơn, bạn có thể chỉ cho phép SSH từ IP cụ thể: ufw allow from your_home_ip to any port 22
ufw allow ssh

# Kích hoạt UFW
echo "Kích hoạt UFW..."
ufw enable

# Hiển thị trạng thái UFW
echo "Trạng thái UFW hiện tại:"
ufw status verbose

#-----------------------------------------------------------------------------------
# HOÀN TẤT CÀI ĐẶT
#-----------------------------------------------------------------------------------
echo "=========================================================================="
echo "===== CÀI ĐẶT HOÀN TẤT! ====="
echo ""
echo "Vui lòng truy cập các dịch vụ qua các URL sau:"
echo "  - Portainer (Quản lý Docker): https://<IP_VPS_CUA_BAN>:9443"
echo "    -> Lần đầu truy cập, bạn sẽ cần tạo tài khoản quản trị."
echo ""
echo "  - Nginx Proxy Manager (Giao diện quản lý): http://<IP_VPS_CUA_BAN>:81"
echo "    -> Tài khoản mặc định:"
echo "    -> Email:    admin@example.com"
echo "    -> Mật khẩu: changeme (Hãy đổi ngay sau khi đăng nhập)"
echo ""
echo "  - AdGuard Home (Chặn quảng cáo): http://<IP_VPS_CUA_BAN>:3000"
echo "    -> Lần đầu truy cập, bạn sẽ được hướng dẫn qua các bước thiết lập."
echo ""
echo "LƯU Ý QUAN TRỌNG VỀ TƯỜNG LỬA:"
echo "Tường lửa UFW đã được kích hoạt và CHỈ cho phép truy cập từ các địa chỉ IP"
echo "trong danh sách tại: $IP_WHITELIST_URL"
echo "Để truy cập các dịch vụ trên, đảm bảo IP của bạn nằm trong danh sách này."
echo "Nếu bị khóa, bạn cần truy cập VPS qua console của nhà cung cấp để sửa quy tắc UFW."
echo ""
echo "Để chạy các lệnh docker không cần sudo, bạn có thể cần đăng xuất và đăng nhập lại."
echo "=========================================================================="
