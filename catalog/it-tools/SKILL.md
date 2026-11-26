---
name: install-app
description: Cài IT-Tools 2024.10.22 (Docker, trang tĩnh) lên VPS Ubuntu của khách Tino, mở HTTPS qua Caddy có hỏi tài khoản.
metadata:
  repo: CorentinTh/it-tools
  ref: 5732483fc24a6e6818839060bdf3cc7d9d324b9f
  category: dev
  title: IT-Tools
  summary_vi: Bộ hơn 80 công cụ nhỏ cho dân IT — mã hoá, JSON, UUID, mạng, chuyển đổi.
  min_cpu: 1
  min_ram_mb: 512
  min_disk_gb: 5
  os: ubuntu-24.04
  port: 8080
  healthcheck: /
  license: GPL-3.0
---

# IT-Tools

Script cài: `app.sh` + `lib/install.sh` → `install.sh`. `ref` = commit của tag `v2024.10.22-7ca5933` (bản phát hành mới nhất);
image `corentinth/it-tools:2024.10.22-7ca5933` (nginx phục vụ trang tĩnh, cổng 80) ghim theo digest. Ứng dụng không có đăng nhập
nên `APP_AUTH=basic`: Caddy hỏi tài khoản quản trị trước khi vào.
