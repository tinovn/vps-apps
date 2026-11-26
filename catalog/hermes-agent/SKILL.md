---
name: install-app
description: Cài Hermes Agent 0.23.2 (Docker, gateway + web dashboard) lên VPS Ubuntu của khách Tino, dashboard chỉ nghe 127.0.0.1 có đăng nhập rồi mới mở HTTPS qua Caddy.
metadata:
  repo: NousResearch/hermes-agent
  ref: ae2a81ccc00e9b7c06301523e5bb09608397149c
  category: ai
  title: Hermes Agent
  summary_vi: Trợ lý AI cá nhân chạy 24/7, tự học kỹ năng, trò chuyện qua Telegram và trang quản trị web.
  min_cpu: 1
  min_ram_mb: 2048
  min_disk_gb: 20
  os: ubuntu-24.04
  port: 9119
  healthcheck: /api/status
  license: MIT
---

# Hermes Agent

Script cài: `app.sh` + `lib/install.sh` → `install.sh`. `ref` = commit của tag `v0.23.2`; image `nousresearch/hermes-agent:v0.23.2` ghim theo digest.
Dashboard (`HERMES_DASHBOARD=1`, s6) nghe `127.0.0.1:9119`; `HERMES_DASHBOARD_PUBLIC_URL` bật cổng đăng nhập, provider `basic` qua `HERMES_DASHBOARD_BASIC_AUTH_*`
(website/docs/user-guide/docker.md, website/docs/user-guide/features/web-dashboard.md, hermes_cli/web_server_boundary.py). Đăng nhập thử: `POST /auth/password-login` (hermes_cli/dashboard_auth/routes.py).
