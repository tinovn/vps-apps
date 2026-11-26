---
name: install-app
description: Cài Metabase 0.65.4 (Docker, PostgreSQL 17 làm app DB) lên VPS Ubuntu của khách Tino, tạo quản trị qua API setup rồi mới mở HTTPS qua Caddy.
metadata:
  repo: metabase/metabase
  ref: b18ec8de2133c2aab68fa151a4858cbbcd396327
  category: data
  title: Metabase
  summary_vi: Dashboard và báo cáo từ cơ sở dữ liệu của bạn, hỏi dữ liệu không cần viết SQL.
  min_cpu: 2
  min_ram_mb: 2048
  min_disk_gb: 10
  os: ubuntu-24.04
  port: 3000
  healthcheck: /api/health
  license: AGPL-3.0
---

# Metabase

`ref` = commit của tag `v0.65.4`; image `metabase/metabase` (bản OSS, AGPL) ghim theo digest; app DB là PostgreSQL (`MB_DB_*`).
Admin: `GET /api/session/properties` lấy `setup-token` khi `has-user-setup` còn false, `POST /api/setup` (`src/metabase/setup_rest/api.clj`: `prefs` chỉ nhận `site_name`, `site_locale`),
đăng nhập thử `POST /api/session` (`src/metabase/session/api.clj`). `/api/health` trả 503 tới khi khởi động xong (`src/metabase/server/routes.clj`).
