---
name: install-app
description: Cài Healthchecks 5.0.3 (Docker, SQLite) lên VPS Ubuntu của khách Tino, tắt đăng ký tự do, tạo quản trị qua manage.py rồi mới mở HTTPS qua Caddy.
metadata:
  repo: healthchecks/healthchecks
  ref: 51a503531d845fc11d5ef270d576c59c300e3620
  category: monitoring
  title: Healthchecks
  summary_vi: Theo dõi cron job, tác vụ định kỳ, sao lưu; báo ngay khi một tác vụ không chạy đúng giờ.
  min_cpu: 1
  min_ram_mb: 1024
  min_disk_gb: 10
  os: ubuntu-24.04
  port: 8000
  healthcheck: /health
  license: BSD-3-Clause
---

# Healthchecks

Script cài: `app.sh` + `lib/install.sh` → `install.sh`. `ref` = commit của tag `v5.0.3`; image `healthchecks/healthchecks` ghim theo digest; biến môi trường theo hc/settings.py và docker/.env.example.
Gunicorn đã tin `X-Forwarded-Proto` (docker/gunicorn.conf.py). `/health` bỏ qua ALLOWED_HOSTS (hc/api/middleware.py). Quản trị đăng nhập bằng email, tạo như
`createsuperuser` (hc/accounts/management/commands/createsuperuser.py: `_make_user`, `set_password`, is_staff/is_superuser) trong `manage.py shell`, mật khẩu qua biến môi trường; đăng nhập thử bằng `authenticate()` (hc/accounts/backends.py).
