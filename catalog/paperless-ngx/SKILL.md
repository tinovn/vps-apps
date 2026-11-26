---
name: install-app
description: Cài Paperless-ngx 3.5.0 (Docker, PostgreSQL 18, Valkey) lên VPS Ubuntu của khách Tino, image tự tạo quản trị từ biến môi trường rồi mới mở HTTPS qua Caddy.
metadata:
  repo: paperless-ngx/paperless-ngx
  ref: bfd0d7fe3671cb8ffa28fb5ea69f6aef817dca5a
  category: team
  title: Paperless-ngx
  summary_vi: Số hoá giấy tờ — quét, OCR tiếng Việt, gắn thẻ và tìm kiếm hoá đơn, hợp đồng, chứng từ trong vài giây.
  min_cpu: 1
  min_ram_mb: 2048
  min_disk_gb: 20
  os: ubuntu-24.04
  port: 8000
  healthcheck: /accounts/login/
  license: GPL-3.0
---

# Paperless-ngx

Script cài: `app.sh` + `lib/install.sh` → `install.sh`. `ref` = commit của tag `v3.5.0`; image `ghcr.io/paperless-ngx/paperless-ngx:3.5.0`
ghim digest, compose theo `docker/compose/docker-compose.postgres.yml`. Quản trị: `PAPERLESS_ADMIN_USER/PASSWORD` → s6 `init-superuser`
chạy `manage_superuser` (`src/documents/management/commands/manage_superuser.py`); `PAPERLESS_ALLOWED_HOSTS` thêm `127.0.0.1` vì có
`PAPERLESS_URL` thì Django chỉ nhận host đó + localhost (`src/paperless/settings/__init__.py`); đăng nhập thử `POST /api/token/`.
