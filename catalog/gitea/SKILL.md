---
name: install-app
description: Cài Gitea 28.4.0 (Docker, SQLite) lên VPS Ubuntu của khách Tino, tạo quản trị bằng CLI rồi mới mở HTTPS qua Caddy.
metadata:
  repo: go-gitea/gitea
  ref: 0b5dfdeeeaadf6350314246c5936b53cce38170c
  category: dev
  title: Gitea
  summary_vi: Máy chủ Git riêng như GitHub thu nhỏ — kho mã, pull request, issue, CI Actions.
  min_cpu: 1
  min_ram_mb: 1024
  min_disk_gb: 10
  os: ubuntu-24.04
  port: 3000
  healthcheck: /api/healthz
  license: MIT
---

# Gitea

Script cài: `app.sh` + `lib/install.sh` → `install.sh`. `ref` = commit của tag `v28.4.0`; image ghim theo digest.
Cấu hình qua biến `GITEA__…` (INSTALL_LOCK, tắt đăng ký và SSH), quản trị tạo bằng `gitea admin user create`.
