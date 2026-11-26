---
name: install-app
description: Cài code-server 4.145.2 (VS Code trên trình duyệt, Docker) lên VPS Ubuntu của khách Tino, bảo vệ bằng mật khẩu rồi mới mở HTTPS qua Caddy.
metadata:
  repo: coder/code-server
  ref: 302bc77436721f5a474e06d1fe34cf8f86195d5e
  category: dev
  title: code-server
  summary_vi: Lập trình bằng VS Code ngay trên trình duyệt, mở từ máy nào cũng được.
  min_cpu: 1
  min_ram_mb: 1024
  min_disk_gb: 10
  os: ubuntu-24.04
  port: 8080
  healthcheck: /healthz
  license: MIT
---

# code-server

Script cài: `app.sh` + `lib/install.sh` → `install.sh`. `ref` = commit của tag `v4.145.2`; image `codercom/code-server:4.145.2`
ghim theo digest. Mật khẩu qua biến `PASSWORD` (auth mặc định là password); đăng nhập thử bằng `POST /login`
(`src/node/routes/login.ts`: đúng mật khẩu thì đặt cookie và chuyển hướng). Không có tên tài khoản; `/healthz` không cần đăng nhập.
