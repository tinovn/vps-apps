---
name: install-app
description: Cài LiteLLM Proxy 1.109.1 (Docker, PostgreSQL 16) lên VPS Ubuntu của khách Tino, quản trị bằng UI_USERNAME/UI_PASSWORD, đăng nhập thử rồi mới mở HTTPS qua Caddy.
metadata:
  repo: BerriAI/litellm
  ref: 6c4ead4fc064d14e36b0c69d6795acc130c866bf
  category: ai
  title: LiteLLM
  summary_vi: Cổng AI gọi hơn 100 mô hình theo chuẩn OpenAI, có khoá ảo, ngân sách và thống kê chi phí.
  min_cpu: 2
  min_ram_mb: 2048
  min_disk_gb: 20
  os: ubuntu-24.04
  port: 4000
  healthcheck: /health/liveliness
  license: MIT (trừ thư mục enterprise/)
---

# LiteLLM

`ref` = commit của tag `v1.109.1`; image `ghcr.io/berriai/litellm-database` (Prisma có sẵn) và `postgres:16.16-alpine` ghim theo digest.
Biến theo `docker/docker-compose.quickstart.yml`: `LITELLM_MASTER_KEY` và `LITELLM_SALT_KEY` dạng `sk-…`, `DATABASE_URL`, `STORE_MODEL_IN_DB=True`.
Quản trị là `UI_USERNAME`/`UI_PASSWORD` (`litellm/proxy/auth/login_utils.py`), đăng nhập thử bằng `POST /v2/login`; khoá master kiểm bằng `GET /v1/models`.
Giấy phép: MIT, riêng `enterprise/` theo `enterprise/LICENSE.md` (tính năng trả phí, không bật).
