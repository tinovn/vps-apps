---
name: install-app
description: Cài Dify 1.19.0 (Docker Compose chính thức của repo, PostgreSQL + Weaviate) lên VPS Ubuntu của khách Tino, tạo tài khoản chủ qua API setup rồi mới mở HTTPS qua Caddy.
metadata:
  repo: langgenius/dify
  ref: 8e689e868b63b6dd2b449d0eb568ca5cc7127759
  category: ai
  title: Dify
  summary_vi: Nền tảng dựng chatbot, agent và quy trình AI kéo thả, kết nối nhiều mô hình và kho tri thức.
  min_cpu: 2
  min_ram_mb: 4096
  min_disk_gb: 40
  os: ubuntu-24.04
  port: 8080
  healthcheck: /console/api/setup
  license: Dify Open Source License
---

# Dify

Script cài: `app.sh` + `lib/install.sh` → `install.sh`. `ref` = commit của tag `1.19.0`; tải nguyên thư mục `docker/` ở commit đó
(codeload tarball) vì `docker-compose.yaml` cần `envs/*.defaults`, `nginx/`, `ssrf_proxy/`. **Image theo tag như tệp upstream, không ghim digest**
(có cả `nginx:latest`, `ubuntu/squid:latest`, `busybox:latest`). `compose.yaml` = `docker-compose.yaml` với nginx/plugin debug chỉ ở 127.0.0.1, bỏ 443.
`.env` theo `docker/.env.example` + `docker/README.md` (COMPOSE_PROFILES, token sandbox, khoá plugin/sandbox, mật khẩu DB/Redis, URL công khai).
Chủ tạo bằng `POST /console/api/setup`, đăng nhập thử `POST /console/api/login` (mật khẩu base64) — `api/controllers/console/setup.py`, `auth/login.py`.
Giấy phép: Apache-2.0 kèm điều kiện (không chạy SaaS nhiều tenant, giữ logo Dify) — không phải OSI.
