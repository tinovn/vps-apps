---
name: install-app
description: Cài Directus 12.6.1 (Docker, PostgreSQL 17) lên VPS Ubuntu của khách Tino, tạo quản trị bằng biến bootstrap rồi mới mở HTTPS qua Caddy.
metadata:
  repo: directus/directus
  ref: b17d2e94ac8dd118f6c3c28b5b04337e97fdd418
  category: data
  title: Directus
  summary_vi: Biến cơ sở dữ liệu thành API và trang quản trị nội dung (headless CMS) không cần lập trình.
  min_cpu: 1
  min_ram_mb: 1024
  min_disk_gb: 10
  os: ubuntu-24.04
  port: 8055
  healthcheck: /server/ping
  license: MSCL-1.0
---

# Directus

`ref` = commit của tag `v12.6.1`; image ghim theo digest. Entrypoint chạy `directus bootstrap` (`docker-entrypoint.cjs`, `api/src/cli/commands/bootstrap/index.ts`):
CSDL trống thì tạo quản trị từ `ADMIN_EMAIL`/`ADMIN_PASSWORD` (`api/src/utils/create-admin.ts`), CSDL đã có thì bỏ qua. Đăng nhập thử `POST /auth/login`.
Giấy phép `license` = Monospace Sustainable Core License 1.0 (không phải OSI); bản Core không key: 3 seat, 25 collection, 5 flow, telemetry bắt buộc (`@directus/license` 0.6.1).
