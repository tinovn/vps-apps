---
name: install-app
description: Cài Qdrant 1.20.2 (Docker) lên VPS Ubuntu của khách Tino, khoá API là mật khẩu quản trị, chỉ mở REST qua HTTPS bằng Caddy.
metadata:
  repo: qdrant/qdrant
  ref: 23065a0bf6857c3e5da45f6c8939cc746cc0580e
  category: data
  title: Qdrant
  summary_vi: Cơ sở dữ liệu vector cho tìm kiếm ngữ nghĩa, RAG và ứng dụng AI.
  min_cpu: 1
  min_ram_mb: 1024
  min_disk_gb: 10
  os: ubuntu-24.04
  port: 6333
  healthcheck: /healthz
  license: Apache-2.0
---

# Qdrant

`ref` = commit của tag `v1.20.2`; image `qdrant/qdrant` ghim theo digest. Khoá API đặt bằng `QDRANT__SERVICE__API_KEY`
(`config/config.yaml`, mục `service.api_key`); `/`, `/healthz`, `/readyz`, `/livez` và `/dashboard` không cần khoá (`src/actix/mod.rs`).
Không có tài khoản: kiểm khoá bằng `GET /collections` với header `api-key`, thiếu khoá phải trả 401 (`src/common/auth/mod.rs`). gRPC 6334 không publish.
