---
name: install-app
description: Cài Activepieces 0.93.0 Community (Docker, PostgreSQL + Redis) lên VPS Ubuntu của khách Tino, tạo tài khoản quản trị qua API rồi mới mở HTTPS qua Caddy.
metadata:
  repo: activepieces/activepieces
  ref: dec8e16d4e02ee1fe9a5cdfb1a30c7a03785401b
  category: automation
  title: Activepieces
  summary_vi: Tự động hoá công việc như Zapier: nối hàng trăm ứng dụng, có bước AI, giao diện kéo thả dễ dùng.
  min_cpu: 2
  min_ram_mb: 4096
  min_disk_gb: 20
  os: ubuntu-24.04
  port: 8080
  healthcheck: /api/v1/health
  license: MIT
---

# Activepieces

Script cài: `app.sh` + `lib/install.sh` → `install.sh`. `ref` = commit của tag `0.93.0`; image ghim theo digest. Theo `docker-compose.yml`
và `.env.example` của tag (PostgreSQL pgvector + Redis), nhưng một container `WORKER_AND_APP` (mặc định của `docker-entrypoint.sh`) thay app + 5 worker.
Quản trị: `POST /api/v1/authentication/sign-up` (tài khoản đầu tiên tạo nền tảng, bản Community tự xác minh email; sau đó đăng ký cần lời mời),
đăng nhập thử `POST /api/v1/authentication/sign-in` (`packages/server/api/src/app/authentication/`). Giấy phép MIT cho bản Community (trừ thư mục `ee`).
