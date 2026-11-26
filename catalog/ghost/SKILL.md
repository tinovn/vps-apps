---
name: install-app
description: Cài Ghost 6.77.0 (Docker, MySQL 8.0) lên VPS Ubuntu của khách Tino, tạo chủ site qua Admin API rồi mới mở HTTPS qua Caddy.
metadata:
  repo: TryGhost/Ghost
  ref: 228c3e2db9c590ec9fbfa7986509b69ebe4e19c2
  category: web
  title: Ghost
  summary_vi: Blog, tạp chí online và bản tin email trả phí, giao diện viết bài gọn đẹp.
  min_cpu: 1
  min_ram_mb: 2048
  min_disk_gb: 10
  os: ubuntu-24.04
  port: 2368
  healthcheck: /ghost/api/admin/site/
  license: MIT
---

# Ghost

Script cài: `app.sh` + `lib/install.sh` → `install.sh`. `ref` = commit của tag `v6.77.0`; image `ghost` chính thức + `mysql:8.0.46`
(cùng bản/digest với compose của TryGhost/ghost-docker), ghim theo digest. Chủ site tạo bằng `POST /ghost/api/admin/authentication/setup/`,
đăng nhập thử bằng `POST /ghost/api/admin/session/` (kiểm Origin) — `ghost/core/server/api/endpoints/authentication.js`, `auth/session/`.
`security__staffDeviceVerification=false` vì mặc định Ghost bắt mã xác minh qua email (`shared/config/defaults.json`).
