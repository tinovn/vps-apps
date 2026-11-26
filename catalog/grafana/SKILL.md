---
name: install-app
description: Cài Grafana OSS 13.3.1 (Docker, SQLite) lên VPS Ubuntu của khách Tino, tạo quản trị bằng biến môi trường rồi mới mở HTTPS qua Caddy.
metadata:
  repo: grafana/grafana
  ref: 5db6ba887630c7fa12e5bfd063f2fa854025468c
  category: monitoring
  title: Grafana
  summary_vi: Bảng điều khiển biểu đồ, cảnh báo cho số liệu máy chủ, cơ sở dữ liệu, ứng dụng.
  min_cpu: 1
  min_ram_mb: 1024
  min_disk_gb: 10
  os: ubuntu-24.04
  port: 3000
  healthcheck: /api/health
  license: AGPL-3.0
---

# Grafana

Script cài: `app.sh` + `lib/install.sh` → `install.sh`. `ref` = commit của tag `v13.3.1`; image `grafana/grafana` (bản OSS, docs/sources/setup-grafana/installation/docker) ghim theo digest.
Quản trị tạo lúc khởi động đầu bằng `GF_SECURITY_ADMIN_USER` / `GF_SECURITY_ADMIN_PASSWORD` (conf/defaults.ini `[security]`, pkg/services/sqlstore/sqlstore.go `ensureMainOrgAndAdminUser`), đăng nhập thử `GET /api/user` bằng Basic auth.
