---
name: install-app
description: Cài LibreChat 0.8.8 (Docker, MongoDB, Meilisearch) lên VPS Ubuntu của khách Tino, tắt đăng ký tự do, tạo quản trị bằng create-user rồi mới mở HTTPS qua Caddy.
metadata:
  repo: LibreChat-AI/LibreChat
  ref: e8f3be08623663d4ad7f7241e693c94469b63bb0
  category: ai
  title: LibreChat
  summary_vi: Giao diện chat AI kiểu ChatGPT cho cả nhóm, dùng khoá OpenAI, Claude, Gemini của riêng bạn.
  min_cpu: 1
  min_ram_mb: 2048
  min_disk_gb: 20
  os: ubuntu-24.04
  port: 3080
  healthcheck: /health
  license: MIT
---

# LibreChat

Script cài: `app.sh` + `lib/install.sh` → `install.sh`. `ref` = commit của tag `v0.8.8` (repo không có release ổn định trên GitHub, mọi release đánh dấu pre-release; `v0.8.8` là tag không rc mới nhất); image `ghcr.io/librechat-ai/librechat:v0.8.8` ghim digest, MongoDB/Meilisearch theo `deploy-compose.yml` ở cùng tag, bỏ rag_api/vectordb cho nhẹ.
Biến môi trường theo `.env.example` (ALLOW_REGISTRATION=false, khoá `user_provided`); quản trị tạo bằng `config/create-user.js` (người dùng đầu tiên là ADMIN, `api/server/services/AuthService.js`), đăng nhập thử `POST /api/auth/login` (`api/server/routes/auth.js`).
