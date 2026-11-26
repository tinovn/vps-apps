---
name: install-app
description: Cài listmonk 6.2.0 (Docker, PostgreSQL 17) lên VPS Ubuntu của khách Tino, tạo quản trị khi khởi tạo CSDL rồi mới mở HTTPS qua Caddy.
metadata:
  repo: knadh/listmonk
  ref: ef0a75872463f10a4848af6c547d1c057405453a
  category: web
  title: listmonk
  summary_vi: Gửi bản tin, email marketing cho danh sách khách hàng lớn, tự quản dữ liệu.
  min_cpu: 1
  min_ram_mb: 1024
  min_disk_gb: 10
  os: ubuntu-24.04
  port: 9000
  healthcheck: /health
  license: AGPL-3.0
---

# listmonk

Script cài: `app.sh` + `lib/install.sh` → `install.sh`. `ref` = commit của tag `v6.2.0` (bản ổn định mới nhất; v7 còn beta); image
`listmonk/listmonk:v6.2.0` ghim theo digest, compose theo `docker-compose.yml` của repo. Quản trị tạo bởi `--install --idempotent`
từ `LISTMONK_ADMIN_USER`/`LISTMONK_ADMIN_PASSWORD` (`cmd/install.go`); `app.root_url` sửa trong bảng `settings`; đăng nhập thử
bằng `POST /admin/login` (`cmd/auth.go`). Healthcheck công khai là `/health` (`/api/health` cần đăng nhập, `cmd/handlers.go`).
