---
name: install-app
description: Cài Open WebUI 0.13.3 (Docker, SQLite) lên VPS Ubuntu của khách Tino, tạo quản trị bằng biến môi trường, tắt đăng ký rồi mới mở HTTPS qua Caddy.
metadata:
  repo: open-webui/open-webui
  ref: b0e6098e940942281d9c83f3529ea117287a3a22
  category: ai
  title: Open WebUI
  summary_vi: Giao diện chat AI như ChatGPT cho cả nhóm, dùng OpenAI, Gemini, Ollama và tài liệu riêng.
  min_cpu: 1
  min_ram_mb: 2048
  min_disk_gb: 20
  os: ubuntu-24.04
  port: 8080
  healthcheck: /health
  license: Open WebUI License
---

# Open WebUI

Script cài: `app.sh` + `lib/install.sh` → `install.sh`. `ref` = commit của tag `v0.13.3`; image `ghcr.io/open-webui/open-webui` ghim
theo digest. Quản trị tạo lúc khởi động bằng `WEBUI_ADMIN_EMAIL`/`WEBUI_ADMIN_PASSWORD` khi chưa có người dùng (`backend/open_webui/env.py`,
`main.py`, `utils/auth.py::create_admin_user`), sau đó `ui.enable_signup` tắt; đăng nhập thử `POST /api/v1/auths/signin`.
Giấy phép Open WebUI License: BSD-3-Clause kèm điều khoản giữ thương hiệu Open WebUI (không phải OSI).
