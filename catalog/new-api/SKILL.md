---
name: install-app
description: Cài New API 0.13.2 (Docker, SQLite) lên VPS Ubuntu của khách Tino, tạo root qua API khởi tạo, tắt đăng ký rồi mới mở HTTPS qua Caddy.
metadata:
  repo: QuantumNous/new-api
  ref: bee339d279ccecbf8c8a89e14ddbbd902f78bd5d
  category: ai
  title: New API
  summary_vi: Cổng API gom nhiều mô hình AI (OpenAI, Claude, Gemini…) về một chỗ, chia khoá và hạn mức cho người dùng.
  min_cpu: 1
  min_ram_mb: 1024
  min_disk_gb: 10
  os: ubuntu-24.04
  port: 3000
  healthcheck: /api/status
  license: AGPL-3.0
---

# New API

`ref` = commit của tag `v0.13.2` (bản ổn định mới nhất; các tag `v1.0.0-rc.*` là bản thử); image `calciumion/new-api` ghim theo digest.
Bản này không còn tạo root/123456 lúc khởi động (`createRootAccountIfNeed` không được gọi, `model/main.go`): root tạo bằng
`POST /api/setup` như trình hướng dẫn web (`controller/setup.go`), đăng nhập thử bằng `POST /api/user/login`, rồi `PUT /api/option/`
đặt `RegisterEnabled=false` và `ServerAddress` (`controller/option.go`, `middleware/auth.go` cần header `New-Api-User`).
