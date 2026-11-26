---
name: install-app
description: Cài SearXNG 2026.11.15 (Docker) lên VPS Ubuntu của khách Tino, khoá bằng mật khẩu Basic auth của Caddy rồi mở HTTPS.
metadata:
  repo: searxng/searxng
  ref: 2d500cb6b8e98b5f57fb446786e91f8de03be89f
  category: ai
  title: SearXNG
  summary_vi: Máy tìm kiếm riêng gộp kết quả Google, Bing… không theo dõi người dùng, dùng được cho AI agent.
  min_cpu: 1
  min_ram_mb: 512
  min_disk_gb: 5
  os: ubuntu-24.04
  port: 8080
  healthcheck: /healthz
  license: AGPL-3.0-or-later
---

# SearXNG

Script cài: `app.sh` + `lib/install.sh` → `install.sh`. SearXNG không phát hành tag: image `searxng/searxng:2026.11.15-2d500cb6b`
(ghim digest) có hậu tố là commit rút gọn, `ref` = commit đầy đủ đó trên nhánh master. Cấu hình theo `container/` ở commit này:
entrypoint tạo `settings.yml` từ `settings.template.yml` (secret ngẫu nhiên), biến `SEARXNG_SECRET`/`SEARXNG_BASE_URL`/`SEARXNG_LIMITER`
(`searx/settings_defaults.py`) ghi đè. Không có tài khoản: `APP_AUTH=basic` (Caddy hỏi admin + mật khẩu).
