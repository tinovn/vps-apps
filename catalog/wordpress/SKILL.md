---
name: install-app
description: Cài WordPress 7.1.4 (Docker, MariaDB 11.8) lên VPS Ubuntu của khách Tino, tạo tài khoản quản trị bằng wp-cli rồi mới mở HTTPS qua Caddy.
metadata:
  repo: WordPress/WordPress
  ref: db96f5eaa77a8d3e8eec8923a518fa2326f0d46a
  category: web
  title: WordPress
  summary_vi: Website, blog, trang giới thiệu doanh nghiệp với hàng nghìn giao diện và plugin.
  min_cpu: 1
  min_ram_mb: 1024
  min_disk_gb: 10
  os: ubuntu-24.04
  port: 8080
  healthcheck: /wp-login.php
  license: GPL-2.0
---

# WordPress

Script cài: `app.sh` (phần riêng) + `lib/install.sh` (phần chung) → `install.sh` (sinh bởi `tools/gen_catalog.py`).
`ref` = commit của tag `7.1.4`; image ghim theo digest (`tools/pin_image.py`). Quản trị tạo bằng `wp core install` của
wp-cli trước khi mở HTTPS; image chính thức tự nhận `X-Forwarded-Proto` của Caddy.
