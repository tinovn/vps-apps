---
name: install-app
description: Cài Langflow 1.13.2 (Docker, PostgreSQL 16) lên VPS Ubuntu của khách Tino, tắt tự đăng nhập, tạo superuser rồi mới mở HTTPS qua Caddy.
metadata:
  repo: langflow-ai/langflow
  ref: 8b42952d734de18e34c2838ff6c634efb1815878
  category: ai
  title: Langflow
  summary_vi: Kéo thả để dựng chatbot, agent và luồng RAG với các mô hình AI, xuất thành API.
  min_cpu: 2
  min_ram_mb: 2048
  min_disk_gb: 20
  os: ubuntu-24.04
  port: 7860
  healthcheck: /health
  license: MIT
---

# Langflow

Script cài: `app.sh` + `lib/install.sh` → `install.sh`. `ref` = commit của tag `v1.13.2`; image ghim theo digest; PostgreSQL như
`docker_example/docker-compose.yml`. `LANGFLOW_AUTO_LOGIN=false`, `LANGFLOW_SUPERUSER`/`LANGFLOW_SUPERUSER_PASSWORD` tạo superuser lúc khởi động
(`langflow/services/utils.py::setup_superuser`, giữ mật khẩu cũ nếu đã có), `LANGFLOW_ENABLE_SIGNUP=false` (`lfx/services/settings/auth.py`).
Đăng nhập thử `POST /api/v1/login` rồi `GET /api/v1/users/whoami`.
