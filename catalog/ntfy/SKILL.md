---
name: install-app
description: Cài ntfy 2.38.1 (Docker, SQLite) lên VPS Ubuntu của khách Tino, khoá truy cập ẩn danh, tạo quản trị bằng CLI rồi mới mở HTTPS qua Caddy.
metadata:
  repo: binwiederhier/ntfy
  ref: 7d7dc4f2da111464a04feeee113005078d04fe4a
  category: automation
  title: ntfy
  summary_vi: Gửi thông báo đẩy tới điện thoại, máy tính chỉ bằng một lệnh curl hoặc webhook.
  min_cpu: 1
  min_ram_mb: 512
  min_disk_gb: 5
  os: ubuntu-24.04
  port: 8080
  healthcheck: /v1/health
  license: Apache-2.0 OR GPL-2.0-only
---

# ntfy

Script cài: `app.sh` + `lib/install.sh` → `install.sh`. `ref` = commit của tag `v2.38.1`; image ghim theo digest.
`server.yml` (theo `server/server.yml`): `auth-default-access: deny-all`, `behind-proxy`, `require-login`, tắt đăng ký.
Quản trị tạo bằng `NTFY_PASSWORD=… ntfy user add --role=admin --ignore-exists` (`cmd/user.go`); đăng nhập thử `GET /v1/account` bằng Basic auth.
