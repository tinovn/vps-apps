---
name: install-app
description: Cài Wiki.js 3.4.0 (Docker, PostgreSQL 18) lên VPS Ubuntu của khách Tino, tạo quản trị bằng ADMIN_EMAIL/ADMIN_PASS ở lần chạy đầu rồi mới mở HTTPS qua Caddy.
metadata:
  repo: requarks/wiki
  ref: c711a5a2d5652961658c9f4f81b90665dfeaf929
  category: team
  title: Wiki.js
  summary_vi: Wiki nội bộ cho nhóm — viết tài liệu, hướng dẫn, quy trình với trình soạn thảo trực quan.
  min_cpu: 1
  min_ram_mb: 1024
  min_disk_gb: 10
  os: ubuntu-24.04
  port: 3000
  healthcheck: /_live
  license: AGPL-3.0
---

# Wiki.js

Script cài: `app.sh` + `lib/install.sh` → `install.sh`. `ref` = commit của tag `3.4.0` (Wiki.js 3, đã phát hành chính thức; không còn
trình cài `/finalize` của bản 2.x); image `ghcr.io/requarks/wiki:3.4.0` ghim digest, compose theo `dev/packer/files/wiki/compose.yaml`.
Quản trị: `ADMIN_EMAIL` + `ADMIN_PASS` chỉ đọc ở lần khởi động đầu với CSDL trống (`backend/models/users.ts` `init`); đăng nhập thử
`PUT /_api/sites/<site>/auth/login` rồi bật `trustProxy` bằng `PUT /_api/system/security` (`backend/api/system.ts`).
