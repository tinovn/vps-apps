---
name: install-app
description: Cài Vaultwarden 1.37.5 (Docker, SQLite) lên VPS Ubuntu của khách Tino, tắt đăng ký tự do, bảo vệ trang /admin bằng token Argon2 rồi mới mở HTTPS qua Caddy.
metadata:
  repo: dani-garcia/vaultwarden
  ref: 6ed6921cc2b0e03b4d74189574d2a5e71c512e97
  category: team
  title: Vaultwarden
  summary_vi: Quản lý mật khẩu cho cá nhân và nhóm, dùng ứng dụng Bitwarden trên điện thoại, trình duyệt, máy tính.
  min_cpu: 1
  min_ram_mb: 512
  min_disk_gb: 5
  os: ubuntu-24.04
  port: 8000
  healthcheck: /alive
  license: AGPL-3.0
---

# Vaultwarden

Script cài: `app.sh` + `lib/install.sh` → `install.sh`. `ref` = commit của tag `1.37.5`; image `vaultwarden/server:1.37.5` ghim digest.
Không có tài khoản người dùng sẵn: mật khẩu trong `/root/tino-app.txt` là token vào `/admin` (lưu dạng Argon2id PHC sinh bằng gói `argon2`
theo https://github.com/dani-garcia/vaultwarden/wiki/Enabling-admin-page, đọc qua `ADMIN_TOKEN_FILE` — `src/util.rs` `get_env_str_value`);
`SIGNUPS_ALLOWED=false`, `INVITATIONS_ALLOWED=true`. Kiểm bằng `POST /admin` (`src/api/admin.rs`: đúng 200, sai 401).
