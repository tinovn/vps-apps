---
name: install-app
description: Cài Memos 26.11.1 (Docker, SQLite) lên VPS Ubuntu của khách Tino, tạo quản trị qua API, tắt đăng ký tự do rồi mới mở HTTPS qua Caddy.
metadata:
  repo: usememos/memos
  ref: 938ceae84223a0a7be77720359f2dabdacf97bb8
  category: team
  title: Memos
  summary_vi: Ghi chú nhanh kiểu dòng thời gian, hỗ trợ Markdown, gắn thẻ, chia sẻ ghi chú trong nhóm.
  min_cpu: 1
  min_ram_mb: 512
  min_disk_gb: 5
  os: ubuntu-24.04
  port: 5230
  healthcheck: /healthz
  license: MIT
---

# Memos

Script cài: `app.sh` + `lib/install.sh` → `install.sh`. `ref` = commit của tag `26.11.1`; image chính thức `neosmemo/memos:26.11.1` ghim digest.
Quản trị: người đầu tiên tạo bằng `POST /api/users` khi chưa có ai thành `ADMIN` (`server/api/user_service.go` `CreateUser`); đăng nhập thử
`POST /api/auth/signin` (`proto/api/auth_service.proto`), rồi đặt `disallowUserRegistration` qua `PATCH /api/instance/settings/GENERAL`
(`proto/api/instance_service.proto`). API bản này không còn tiền tố `/api/v1`.
