---
name: install-app
description: Cài Navidrome 0.64.2 (Docker) lên VPS Ubuntu của khách Tino, tạo quản trị đầu tiên qua API rồi mới mở HTTPS qua Caddy.
metadata:
  repo: navidrome/navidrome
  ref: 101145742f4762164202cb4858c9126258bdc463
  category: media
  title: Navidrome
  summary_vi: Máy chủ nhạc riêng như Spotify của bạn — nghe kho nhạc trên trình duyệt và điện thoại.
  min_cpu: 1
  min_ram_mb: 512
  min_disk_gb: 10
  os: ubuntu-24.04
  port: 4533
  healthcheck: /ping
  license: GPL-3.0
---

# Navidrome

`ref` = commit của tag `v0.64.2`; image `deluan/navidrome` ghim theo digest (`/data`, nhạc ở `/music`).
Admin: `POST /auth/createAdmin` (chỉ khi chưa có người dùng, `server/auth.go`), đăng nhập thử `POST /auth/login` (`isAdmin`); `/ping` là heartbeat của chi (`server/server.go`).
