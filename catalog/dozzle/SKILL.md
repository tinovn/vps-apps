---
name: install-app
description: Cài Dozzle 11.4.3 (Docker, đăng nhập simple bằng users.yml) lên VPS Ubuntu của khách Tino, đăng nhập thử rồi mới mở HTTPS qua Caddy.
metadata:
  repo: amir20/dozzle
  ref: 76c2bdae87e9d7e3c7b3d839bd895ce7ba961888
  category: monitoring
  title: Dozzle
  summary_vi: Xem log các container Docker trên VPS theo thời gian thực ngay trong trình duyệt.
  min_cpu: 1
  min_ram_mb: 512
  min_disk_gb: 5
  os: ubuntu-24.04
  port: 8080
  healthcheck: /healthcheck
  license: MIT
---

# Dozzle

Script cài: `app.sh` + `lib/install.sh` → `install.sh`. `ref` = commit của tag `v11.4.3`; image ghim theo digest.
Quản trị: `DOZZLE_AUTH_PROVIDER=simple`, `/data/users.yml` sinh bằng `dozzle generate` với mật khẩu qua stdin (internal/cli/generate_command.go,
docs/guide/authentication/simple.md); đăng nhập thử `POST /api/token` (internal/web/auth.go). `/healthcheck` không cần đăng nhập, ping Docker (docs/guide/healthcheck.md).
