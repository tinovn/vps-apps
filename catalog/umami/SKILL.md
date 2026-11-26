---
name: install-app
description: Cài Umami 3.5.0 (Docker, PostgreSQL 17) lên VPS Ubuntu của khách Tino, đổi mật khẩu admin mặc định rồi mới mở HTTPS qua Caddy.
metadata:
  repo: umami-software/umami
  ref: d3c62a805beda8643cb468924dda38617fb4c286
  category: web
  title: Umami
  summary_vi: Thống kê lượt truy cập website gọn nhẹ, không cookie, thay Google Analytics.
  min_cpu: 1
  min_ram_mb: 1024
  min_disk_gb: 10
  os: ubuntu-24.04
  port: 3000
  healthcheck: /api/heartbeat
  license: MIT
---

# Umami

Script cài: `app.sh` + `lib/install.sh` → `install.sh`. `ref` = commit của tag `v3.5.0`; image `ghcr.io/umami-software/umami:3.5.0`
ghim theo digest, theo `docker-compose.yml` của repo. Migration tạo `admin`/`umami` (`src/lib/password.ts`); script đăng nhập
`POST /api/auth/login`, đổi bằng `POST /api/me/password` (`src/app/api/me/password/route.ts`) rồi đăng nhập thử bằng mật khẩu mới.
