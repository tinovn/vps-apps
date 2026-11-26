---
name: install-app
description: Cài Beszel 0.21.2 (hub + agent, Docker) lên VPS Ubuntu của khách Tino, tạo quản trị bằng biến môi trường, tự gắn agent giám sát chính VPS rồi mới mở HTTPS qua Caddy.
metadata:
  repo: henrygd/beszel
  ref: c97759f0ca4badc824ab0ff43f1571cc3c8f3a72
  category: monitoring
  title: Beszel
  summary_vi: Giám sát nhẹ nhiều máy chủ — CPU, RAM, ổ đĩa, mạng, Docker — kèm lịch sử và cảnh báo.
  min_cpu: 1
  min_ram_mb: 512
  min_disk_gb: 10
  os: ubuntu-24.04
  port: 8090
  healthcheck: /api/health
  license: MIT
---

# Beszel

Script cài: `app.sh` + `lib/install.sh` → `install.sh`. `ref` = commit của tag `v0.21.2`; image hub và agent ghim theo digest.
Quản trị: `USER_EMAIL` / `USER_PASSWORD` tạo superuser và người dùng role admin ở migration đầu (internal/migrations/initial-settings.go); đăng nhập thử
`auth-with-password`. Agent: lấy khoá `GET /api/beszel/info`, bật token phổ dụng tạm `POST /api/beszel/universal-token` (internal/hub/api.go, agent_connect.go),
chạy agent mạng host với `HUB_URL`, `KEY`, `TOKEN`, `DISABLE_SSH=true` (agent/client.go, agent/connection_manager.go).
