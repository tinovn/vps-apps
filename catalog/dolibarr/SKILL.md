---
name: install-app
description: Cài Dolibarr 24.0.2 (Docker, MariaDB 11.8) lên VPS Ubuntu của khách Tino, khởi tạo CSDL kèm quản trị rồi mới mở HTTPS qua Caddy.
metadata:
  repo: Dolibarr/dolibarr
  ref: 7e927764767343334aaa067ca5ec054cfea0a26b
  category: web
  title: Dolibarr
  summary_vi: Quản lý doanh nghiệp nhỏ — khách hàng, báo giá, hoá đơn, kho, nhân sự.
  min_cpu: 1
  min_ram_mb: 1024
  min_disk_gb: 10
  os: ubuntu-24.04
  port: 8080
  healthcheck: /
  license: GPL-3.0
---

# Dolibarr

Script cài: `app.sh` + `lib/install.sh` → `install.sh`. `ref` = commit của tag `24.0.2` (bản mới nhất có image trên Docker Hub; GitHub đã
có 24.0.3 nhưng chưa có image); image `dolibarr/dolibarr:24.0.2` ghim theo digest. Cài bằng `docker-run.sh` của Dolibarr/dolibarr-docker
(`DOLI_INSTALL_AUTO=1`: tạo bảng, chèn quản trị `DOLI_ADMIN_LOGIN`/`DOLI_ADMIN_PASSWORD`, khoá `install.lock`). Đăng nhập thử bằng
`checkLoginPassEntity()` (`htdocs/core/lib/security2.lib.php`) qua PHP CLI.
