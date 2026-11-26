---
name: install-app
description: Cài Vane 1.12.2 (tên cũ Perplexica, Docker, gộp sẵn SearXNG) lên VPS Ubuntu của khách Tino, Caddy hỏi tài khoản vì ứng dụng không có đăng nhập.
metadata:
  repo: ItzCrazyKns/Vane
  ref: 9e8d883768c43520464345fefe58654f5cee451b
  category: ai
  title: Vane
  summary_vi: Máy tìm kiếm AI riêng kiểu Perplexity: hỏi đáp có trích nguồn, dùng khoá AI của bạn.
  min_cpu: 1
  min_ram_mb: 2048
  min_disk_gb: 30
  os: ubuntu-24.04
  port: 3000
  healthcheck: /
  license: MIT
---

# Vane

Script cài: `app.sh` + `lib/install.sh` → `install.sh`. `ref` = commit của tag `v1.12.2`; image `itzcrazykns1337/vane:v1.12.2` (= `full-v1.12.2`, gộp SearXNG, theo README và `docker-compose.yaml`) ghim digest.
Vane không có tài khoản: `APP_AUTH=basic`, Caddy hỏi admin/mật khẩu. Cấu hình mô hình làm trong màn hình thiết lập, lưu ở volume `/home/vane/data`.
