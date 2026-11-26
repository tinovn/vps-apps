---
name: install-app
description: Cài Huginn 2026.11.09 (Docker, PostgreSQL 17) lên VPS Ubuntu của khách Tino, tạo quản trị bằng db:seed, khoá đăng ký bằng mã mời rồi mới mở HTTPS qua Caddy.
metadata:
  repo: huginn/huginn
  ref: 639c050b2bf4e14ef9983012af99dfc1dc68b334
  category: automation
  title: Huginn
  summary_vi: Tạo các agent tự theo dõi website, RSS, API và tự gửi cảnh báo, như IFTTT/Zapier tự host.
  min_cpu: 1
  min_ram_mb: 2048
  min_disk_gb: 10
  os: ubuntu-24.04
  port: 3000
  healthcheck: /users/sign_in
  license: MIT
---

# Huginn

Script cài: `app.sh` + `lib/install.sh` → `install.sh`. `ref` = commit của tag `v2026.11.09`; image `ghcr.io/huginn/huginn`
(multi-process) ghim theo digest, PostgreSQL ngoài (`docker/multi-process/README.md`, `docker/scripts/setup_env`).
Quản trị tạo bằng `SEED_USERNAME`/`SEED_PASSWORD`/`SEED_EMAIL` khi `rake db:seed` (`db/seeds/seeder.rb`, bỏ qua nếu đã có người dùng);
`INVITATION_CODE` ngẫu nhiên chặn đăng ký tự do; đăng nhập thử qua form Devise `POST /users/sign_in`.
