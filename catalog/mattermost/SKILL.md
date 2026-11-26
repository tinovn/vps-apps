---
name: install-app
description: Cài Mattermost Team Edition 12.1.0 (Docker, PostgreSQL 18) lên VPS Ubuntu của khách Tino, tạo quản trị qua API rồi mới mở HTTPS qua Caddy.
metadata:
  repo: mattermost/mattermost
  ref: 243e3d0135203ab9166fe8f2873b07f697b06fd4
  category: team
  title: Mattermost
  summary_vi: Nhắn tin nhóm như Slack riêng — kênh, tin nhắn trực tiếp, chia sẻ tệp, ứng dụng điện thoại.
  min_cpu: 1
  min_ram_mb: 2048
  min_disk_gb: 20
  os: ubuntu-24.04
  port: 8065
  healthcheck: /api/v4/system/ping
  license: MIT (Team Edition)
---

# Mattermost

Script cài: `app.sh` + `lib/install.sh` → `install.sh`. `ref` = commit của tag `v12.1.0`; image `mattermost/mattermost-team-edition:12.1.0`
ghim digest (bản biên dịch của Mattermost theo MIT, mã nguồn AGPL-3.0 — `LICENSE.txt`). Cấu hình theo https://github.com/mattermost/docker.
Quản trị: người dùng đầu tiên tạo bằng `POST /api/v4/users` được phép khi chưa có ai dù `EnableOpenServer=false` và nhận `system_admin`
(`server/channels/app/user.go` `CreateUserFromSignup`, `app/users/users.go`); đăng nhập thử `POST /api/v4/users/login`.
