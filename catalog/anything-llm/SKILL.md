---
name: install-app
description: Cài AnythingLLM 1.19.0 (Docker) lên VPS Ubuntu của khách Tino, bật chế độ nhiều người dùng với tài khoản quản trị rồi mới mở HTTPS qua Caddy.
metadata:
  repo: Mintplex-Labs/anything-llm
  ref: 9b1fcab141000eaba9f78ed131151de04904454b
  category: ai
  title: AnythingLLM
  summary_vi: Trợ lý AI riêng: chat với tài liệu PDF, Word, website của doanh nghiệp, dùng OpenAI, Gemini hay Ollama.
  min_cpu: 2
  min_ram_mb: 2048
  min_disk_gb: 20
  os: ubuntu-24.04
  port: 3001
  healthcheck: /api/ping
  license: MIT
---

# AnythingLLM

Script cài: `app.sh` + `lib/install.sh` → `install.sh`. `ref` = commit của tag `v1.19.0`; image ghim theo digest; chạy như
`docker/HOW_TO_USE_DOCKER.md` (storage + `.env` của ứng dụng, uid 1000, `SYS_ADMIN`). Quản trị: `POST /api/system/enable-multi-user`
(mở khi chưa có `AUTH_TOKEN`) tạo admin và bật multi-user; đăng nhập thử `POST /api/request-token` (`server/endpoints/system.js`).
