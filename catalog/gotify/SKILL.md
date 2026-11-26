---
name: install-app
description: Cài Gotify 3.1.1 (Docker, SQLite) lên VPS Ubuntu của khách Tino, tạo quản trị bằng biến môi trường rồi mới mở HTTPS qua Caddy.
metadata:
  repo: gotify/server
  ref: e6361caa512547052b1013dbf4544e6d7ff32604
  category: automation
  title: Gotify
  summary_vi: Máy chủ gửi thông báo đẩy riêng tới điện thoại và trình duyệt qua API đơn giản.
  min_cpu: 1
  min_ram_mb: 512
  min_disk_gb: 5
  os: ubuntu-24.04
  port: 8080
  healthcheck: /health
  license: MIT
---

# Gotify

Script cài: `app.sh` + `lib/install.sh` → `install.sh`. `ref` = commit của tag `v3.1.1`; image ghim theo digest.
Quản trị tạo bằng `GOTIFY_DEFAULTUSER_NAME` / `GOTIFY_DEFAULTUSER_PASS` (chỉ khi chưa có người dùng, `database/database.go`),
`GOTIFY_REGISTRATION=false`; đăng nhập thử `GET /current/user` bằng Basic auth (`config/keys.go`, `router/router.go`).
