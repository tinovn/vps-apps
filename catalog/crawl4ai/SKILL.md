---
name: install-app
description: Cài Crawl4AI 0.9.5 (Docker, Chromium headless) lên VPS Ubuntu của khách Tino, bật xác thực Bearer bằng CRAWL4AI_API_TOKEN rồi mới mở HTTPS qua Caddy.
metadata:
  repo: unclecode/crawl4ai
  ref: 838869bdda93f25e6d50b3f50ae9577d9b19a586
  category: ai
  title: Crawl4AI
  summary_vi: Thu thập nội dung website thành Markdown sạch cho AI, RAG và agent qua API.
  min_cpu: 2
  min_ram_mb: 2048
  min_disk_gb: 20
  os: ubuntu-24.04
  port: 11235
  healthcheck: /health
  license: Apache-2.0 + điều khoản ghi công
---

# Crawl4AI

`ref` = commit của tag `v0.9.5`; image `unclecode/crawl4ai:0.9.5` ghim theo digest, compose theo `docker-compose.yml` chính thức (rootfs chỉ đọc, tmpfs, `shm_size`).
Có `CRAWL4AI_API_TOKEN` thì `deploy/docker/entrypoint.sh` mới cho nghe ngoài loopback và `deploy/docker/auth_gate.py` đòi `Authorization: Bearer`
cho mọi đường dẫn trừ `/health`, `/token`, `/` và trang tĩnh `/playground`, `/dashboard`. Token = mật khẩu quản trị; kiểm bằng `GET /schema` (thiếu token → 401).
`LICENSE` là Apache-2.0 kèm yêu cầu ghi công UncleCode/Crawl4AI khi phân phối hoặc dùng công khai.
