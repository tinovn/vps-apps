---
name: install-app
description: Cài Audiobookshelf 2.37.2 (Docker) lên VPS Ubuntu của khách Tino, tạo tài khoản root qua API khởi tạo rồi mới mở HTTPS qua Caddy.
metadata:
  repo: advplyr/audiobookshelf
  ref: edb1f7efc92ecacdef51aafb4d9d5054ce10604f
  category: media
  title: Audiobookshelf
  summary_vi: Thư viện sách nói và podcast riêng, nghe tiếp đúng chỗ đang dừng trên mọi thiết bị.
  min_cpu: 1
  min_ram_mb: 1024
  min_disk_gb: 10
  os: ubuntu-24.04
  port: 13378
  healthcheck: /healthcheck
  license: GPL-3.0
---

# Audiobookshelf

`ref` = commit của tag `v2.37.2`; image `ghcr.io/advplyr/audiobookshelf` ghim theo digest (nghe cổng 80 trong container, `/config`, `/metadata`, `/audiobooks`, `/podcasts`).
Admin: `POST /init` với `newRoot {username, password}` khi `GET /status` có `isInit=false` (`server/Server.js`), đăng nhập thử `POST /login` (`server/Auth.js`, `user.type == "root"`).
