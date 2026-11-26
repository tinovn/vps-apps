---
name: install-app
description: Cài Kutt 3.2.6 (Docker, SQLite) lên VPS Ubuntu của khách Tino, tạo admin đầu tiên qua API rồi mới mở HTTPS qua Caddy.
metadata:
  repo: thedevs-network/kutt
  ref: 6ca803373a3c95f1a92674e9066175aff96cb772
  category: web
  title: Kutt
  summary_vi: Rút gọn link bằng tên miền riêng, có thống kê lượt nhấp và API.
  min_cpu: 1
  min_ram_mb: 1024
  min_disk_gb: 10
  os: ubuntu-24.04
  port: 3000
  healthcheck: /api/health
  license: MIT
---

# Kutt

Script cài: `app.sh` + `lib/install.sh` → `install.sh`. `ref` = commit của tag `v3.2.6`; image `kutt/kutt:v3.2.6` ghim theo digest,
SQLite như `docker-compose.yml` của repo. Admin đầu tiên tạo bằng `POST /api/auth/create-admin` (`server/routes/auth.routes.js`,
`createAdminUser` trong `server/handlers/auth.handler.js`: từ chối khi đã có người dùng), đăng nhập thử bằng `POST /api/auth/login`.
`DISALLOW_REGISTRATION`, `JWT_SECRET`, `DEFAULT_DOMAIN` theo `server/env.js`.
