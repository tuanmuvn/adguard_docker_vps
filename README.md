# Script Tự Động Cài Đặt AdGuard Home & Portainer với SSL và Tường Lửa

<p align="center">
  <img src="https://github.com/AdguardTeam/AdGuardHome/raw/master/doc/adguard_home_lightmode.svg" alt="AdGuard Home logo" width="150px" style="visibility:visible;max-width:100%;"/>
     
  <img src="https://www.docker.com/wp-content/uploads/2022/03/Moby-logo.png" alt="Docker logo" width="120"/>
     
  <img src="https://dqah5woojdp50.cloudfront.net/original/2X/d/d2493a68c9cbaf275d9ac596dca4521c514f0c3e.png" alt="Caddy logo" width="150px" style="visibility:visible;max-width:100%;"/>
     
  <img src="https://www.portainer.io/hubfs/portainer-logo-black.svg" alt="Portainer logo" width="150px" style="visibility:visible;max-width:100%;"/>
</p>

Script này tự động hóa 100% quá trình cài đặt và cấu hình một bộ dịch vụ mạnh mẽ trên máy chủ Debian/Ubuntu, giúp bạn thiết lập một môi trường an toàn và dễ quản lý chỉ trong vài phút.

-   **AdGuard Home**: Chặn quảng cáo và mã độc trên toàn mạng.
-   **Portainer CE**: Giao diện đồ họa để quản lý Docker.
-   **Caddy v2**: Web server tự động cung cấp HTTPS.
-   **UFW Firewall**: Tường lửa bảo vệ VPS, chỉ cho phép truy cập từ các IP tin cậy.

---

## ✅ Yêu Cầu Bắt Buộc

Trước khi chạy script, vui lòng đảm bảo bạn đã chuẩn bị đầy đủ:

1.  **VPS**: Một máy chủ ảo đang chạy hệ điều hành **Debian (11, 12)** hoặc **Ubuntu (20.04, 22.04)**.
2.  **Tên miền**: Hai (2) tên miền hoặc tên miền phụ (subdomain) đã được trỏ **bản ghi A** về địa chỉ IP của VPS.
    -   *Ví dụ*: `adg.example.com` -> `192.0.2.1` và `docker.example.com` -> `192.0.2.1`.
3.  **File Whitelist IP**:
    -   Bạn cần có một file `whitelist_ip.txt` được lưu trên một kho lưu trữ GitHub.
    -   **QUAN TRỌNG NHẤT**: File này **phải chứa địa chỉ IP public của bạn** (mạng bạn đang dùng để SSH vào VPS). Nếu không, bạn sẽ bị khóa khỏi VPS.
    -   Bạn sẽ cần URL "Raw" của file này để điền vào script.

---

## 🚀 Hướng Dẫn Cài Đặt

Script này cần được chạy với quyền quản trị (`root` hoặc `sudo`). Bạn có thể chọn một trong hai cách cài đặt dưới đây.

### ➡️ Cách 1: Cài Đặt Nhanh (Khuyến nghị)

Đây là cách nhanh và tiện lợi nhất. Nó sẽ tải và chạy script bằng một dòng lệnh duy nhất.

Đăng nhập vào VPS và chạy lệnh sau:

```bash
sudo bash <(curl -sSL https://raw.githubusercontent.com/tuanmuvn/adguard_docker_vps/refs/heads/main/setup-adguard-docker.sh)
```
Ghi chú: Hãy thay thế `https://raw.githubusercontent.com/tuanmuvn/adguard_docker_vps/refs/heads/main/setup-adguard-docker.sh` bằng đường dẫn Raw chính xác đến file script của bạn trên GitHub.
### ➡️ Cách 2: Cài Đặt An Toàn (Từng bước)
Cách này cho phép bạn tải script về, tự mình kiểm tra lại nội dung trước khi thực thi.
#### Bước 1: Tải script về máy chủ
```bash
curl -sSLO https://raw.githubusercontent.com/tuanmuvn/adguard_docker_vps/refs/heads/main/setup-adguard-docker.sh
```
#### Bước 2: (Tùy chọn) Xem lại nội dung script để đảm bảo an toàn
```bash
cat setup-adguard-docker.sh
```
#### Bước 3: Cấp quyền thực thi cho file
```bash
chmod +x setup-adguard-docker.sh
```
#### Bước 4: Chạy script với quyền **sudo**
```bash
sudo ./setup-adguard-docker.sh
```
## 🛠️ Cấu Hình Sau Khi Cài Đặt
Khi script chạy xong, các dịch vụ đã hoạt động. Bạn cần thực hiện cấu hình lần đầu:
### 1. Cấu hình AdGuard Home:
Mở trình duyệt, truy cập: `http://<IP-CUA-VPS>:8080`
Làm theo hướng dẫn trên màn hình để thiết lập tài khoản quản trị và mật khẩu.
### 2. Truy cập các dịch vụ qua tên miền an toàn (HTTPS):
Sau khi cấu hình xong, bạn có thể truy cập các dịch vụ bằng tên miền đã thiết lập trong script.
- **AdGuard Home:** `https://adg.example.com`
- Giao diện nội bộ: `http://[IP-VPS]:8080` (AdGuard lần đầu cấu hình) 
- **Portainer:** `https://docker.example.com` (tạo tài khoản quản trị ở lần truy cập đầu tiên)
- Portainer nội bộ:| `http://[IP-VPS]:9000` (không SSL, nội bộ) 
### 🛡️ Cập Nhật Danh Sách IP Cho Phép (Whitelist)
- Khi IP của bạn thay đổi, bạn cần cập nhật lại tường lửa.
- Sửa file: Vào kho lưu trữ GitHub của bạn và cập nhật file whitelist_ip.txt.
- Chạy lại lệnh cấu hình tường lửa: Đăng nhập vào VPS và chạy một script nhỏ sau để áp dụng thay đổi.
```bash
# Di chuyển đến thư mục cài đặt
cd /opt/adguard
# Lấy URL Raw của file whitelist từ script
WHITELIST_URL=$(grep 'WHITELIST_URL=' setup-adguard-ssl.sh | cut -d'"' -f2)
# Tải lại file whitelist mới
curl -fsSL "$WHITELIST_URL" -o whitelist_ip.txt
# Đặt lại và áp dụng lại quy tắc tường lửa
echo "Dang ap dung lai cac quy tac tuong lua..."
sudo ufw --force reset
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
while read -r ip; do [[ -n "$ip" && ! "$ip" =~ ^# ]] && sudo ufw allow from "$ip"; done < whitelist_ip.txt
yes | sudo ufw enable
echo "Hoan tat! Kiem tra trang thai:"
sudo ufw status verbose
```
Cảnh báo: Luôn đảm bảo IP hiện tại của bạn đã có trong file `whitelist_ip.txt` trên **GitHub** TRƯỚC KHI chạy lệnh cập nhật để không tự khóa mình. Nếu không may bị khóa, hãy sử dụng **Recovery Console (hoặc Web Console)** từ nhà cung cấp **VPS** để đăng nhập và chạy lệnh `sudo ufw disable`.
