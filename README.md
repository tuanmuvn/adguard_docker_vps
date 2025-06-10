# Script Tự Động Cài Đặt AdGuard Home & Portainer với SSL và Tường Lửa

<p align="center">
  <img src="https://raw.githubusercontent.com/AdguardTeam/AdGuardHome/master/internal/home/logo.svg" alt="AdGuard Home logo" width="100"/>
     
  <img src="https://www.docker.com/wp-content/uploads/2022/03/Moby-logo.png" alt="Docker logo" width="120"/>
     
  <img src="https://caddyserver.com/resources/images/caddy-logo-fullscreen.svg" alt="Caddy logo" width="100"/>
     
  <img src="https://www.portainer.io/hubfs/Brand%20Assets/Portainer%20Logo/Portainer-Logo-Blue.png" alt="Portainer logo" width="120"/>
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
    -   *Ví dụ*: `adg.vidu.com` -> `192.0.2.1` và `docker.vidu.com` -> `192.0.2.1`.
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
sudo bash <(curl -sSL https://raw.githubusercontent.com/TEN_CUA_BAN/TEN_REPO/main/setup-adguard-ssl.sh)
```
Ghi chú: Hãy thay thế https://raw.githubusercontent.com/TEN_CUA_BAN/TEN_REPO/main/setup-adguard-ssl.sh bằng đường dẫn Raw chính xác đến file script của bạn trên GitHub.
### ➡️ Cách 2: Cài Đặt An Toàn (Từng bước)
Cách này cho phép bạn tải script về, tự mình kiểm tra lại nội dung trước khi thực thi.
