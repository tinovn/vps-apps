---
name: install-app
description: Cài BookStack 26.09.3 (Docker, image linuxserver.io, MariaDB 11.8) lên VPS Ubuntu của khách Tino, đổi tài khoản quản trị mặc định bằng artisan rồi mới mở HTTPS qua Caddy.
metadata:
  repo: BookStackApp/BookStack
  ref: bf680915b6dbaf93eee5234ec72dc33bc5abafbf
  category: team
  title: BookStack
  summary_vi: Kho tài liệu nội bộ sắp xếp theo kệ, sách, chương, trang — dễ viết, dễ tìm cho cả nhóm.
  min_cpu: 1
  min_ram_mb: 1024
  min_disk_gb: 10
  os: ubuntu-24.04
  port: 6875
  healthcheck: /status
  license: MIT
---

# BookStack

Script cài: `app.sh` + `lib/install.sh` → `install.sh`. `ref` = commit của tag `v26.09.3`; BookStack không có image chính thức, dùng
`ghcr.io/linuxserver/bookstack:v26.09.3-ls298` ghim digest (biến môi trường theo https://github.com/linuxserver/docker-bookstack).
Quản trị: migration tạo `admin@admin.com` / `password`; `php artisan bookstack:create-admin --initial` đổi chính tài khoản đó sang email
và mật khẩu của khách (`app/Console/Commands/CreateAdminCommand.php`) trước khi mở HTTPS; đăng nhập thử qua form `/login`.
