---
name: install-app
description: Cài changedetection.io 0.70.3 (Docker, bản nhẹ không kèm Chrome) lên VPS Ubuntu của khách Tino, khoá mật khẩu bằng SALTED_PASS, đăng nhập thử rồi mới mở HTTPS qua Caddy.
metadata:
  repo: dgtlmoon/changedetection.io
  ref: d466b8bb0ad8c64ceec232809f5ef7683b1fce49
  category: monitoring
  title: changedetection.io
  summary_vi: Theo dõi thay đổi trên trang web (giá, tồn kho, nội dung) và báo qua email, Telegram, Discord.
  min_cpu: 1
  min_ram_mb: 1024
  min_disk_gb: 10
  os: ubuntu-24.04
  port: 5000
  healthcheck: /
  license: Apache-2.0
---

# changedetection.io

Script cài: `app.sh` + `lib/install.sh` → `install.sh`. `ref` = commit của tag `0.70.3`; image `ghcr.io/dgtlmoon/changedetection.io` ghim theo digest; compose theo docker-compose.yml của repo.
Ứng dụng chỉ có mật khẩu: khoá bằng biến `SALTED_PASS` = base64(salt 32 byte + PBKDF2-SHA256 100000 vòng) như `User.check_password` (changedetectionio/flask_app.py;
trang Settings ghi "Password is locked", blueprint/settings/__init__.py). Đăng nhập thử qua form `/login` có `csrf_token`. `/` chưa đăng nhập trả 302 về `/login`.
