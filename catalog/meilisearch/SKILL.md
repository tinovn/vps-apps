---
name: install-app
description: Cài Meilisearch 1.57.0 (Docker, chế độ production) lên VPS Ubuntu của khách Tino, khoá master là mật khẩu quản trị, mở HTTPS qua Caddy.
metadata:
  repo: meilisearch/meilisearch
  ref: 1b782653f25c6ff70084c1a510cd6d2608af458d
  category: data
  title: Meilisearch
  summary_vi: Máy tìm kiếm siêu nhanh cho website và ứng dụng, gõ tới đâu ra kết quả tới đó.
  min_cpu: 1
  min_ram_mb: 1024
  min_disk_gb: 10
  os: ubuntu-24.04
  port: 7700
  healthcheck: /health
  license: MIT
---

# Meilisearch

`ref` = commit của tag `v1.57.0`; image `getmeili/meilisearch` (Community Edition, MIT — `.github/workflows/publish-docker-images.yml`; bản EE là image `meilisearch-enterprise`) ghim theo digest.
`MEILI_ENV=production` bắt buộc khoá master ≥ 16 byte (`crates/meilisearch/src/main.rs`) và tắt mini-dashboard, `/` trả `{"status":"Meilisearch is running"}` (`src/lib.rs`).
Không có tài khoản: khoá master = mật khẩu trong `/root/tino-app.txt`, kiểm bằng `GET /keys` với `Authorization: Bearer`.
