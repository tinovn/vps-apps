---
name: install-app
description: Cài Stirling PDF 3.3.0 (Docker) lên VPS Ubuntu của khách Tino, bật đăng nhập với tài khoản quản trị đầu tiên từ biến môi trường rồi mới mở HTTPS qua Caddy.
metadata:
  repo: Stirling-Tools/Stirling-PDF
  ref: 7825214811d98fd3ec260bf315cd998ecb73b36b
  category: team
  title: Stirling PDF
  summary_vi: Bộ công cụ PDF trên trình duyệt — gộp, tách, nén, chuyển Word/ảnh, OCR, ký số, không gửi tệp ra ngoài.
  min_cpu: 1
  min_ram_mb: 2048
  min_disk_gb: 10
  os: ubuntu-24.04
  port: 8080
  healthcheck: /api/v1/info/status
  license: MIT (có phần độc quyền)
---

# Stirling PDF

Script cài: `app.sh` + `lib/install.sh` → `install.sh`. `ref` = commit của tag `v3.3.0`; image `stirlingtools/stirling-pdf:3.3.0` ghim digest
(bản build mặc định đã gồm `app/proprietary` — đăng nhập; `DISABLE_ADDITIONAL_FEATURES` chỉ là cờ lúc build, `settings.gradle`).
Quản trị: `SECURITY_ENABLELOGIN=true` + `SECURITY_INITIALLOGIN_USERNAME/PASSWORD` (`app/core/src/main/resources/settings.yml.template`),
tạo khi CSDL chưa có ai, không bắt đổi mật khẩu (`InitialSecuritySetup.java`); đăng nhập thử `POST /api/v1/auth/login`.
Giấy phép MIT, trừ các thư mục `app/proprietary/`, `engine/`… theo giấy phép riêng (`LICENSE`); miễn phí tối đa 5 người dùng.
