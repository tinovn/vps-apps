---
name: install-app
description: Cài NocoDB 2026.10.1 (Docker, PostgreSQL 17) lên VPS Ubuntu của khách Tino, tạo super admin qua API, tắt đăng ký tự do rồi mới mở HTTPS qua Caddy.
metadata:
  repo: nocodb/nocodb
  ref: 21b0a0b4e71ffc2895034bbb1431045c661d02f0
  category: data
  title: NocoDB
  summary_vi: Biến cơ sở dữ liệu thành bảng tính kiểu Airtable — bảng, form, kanban, API cho nhóm làm việc.
  min_cpu: 1
  min_ram_mb: 2048
  min_disk_gb: 10
  os: ubuntu-24.04
  port: 8080
  healthcheck: /api/v1/health
  license: Sustainable Use
---

# NocoDB

`ref` = commit của tag `2026.10.1`; image ghim theo digest. Compose theo `docker-compose/examples/quickstart-demo` (bỏ redis/worker: bản CE chỉ dùng hàng đợi trong tiến trình, `packages/nocodb/src/modules/jobs/jobs.module.ts`).
Admin: `POST /api/v1/auth/user/signup` khi `GET /api/v1/meta/nocodb/info` báo `firstUser` (người đầu tiên = super, `services/users/users.service.ts`), đăng nhập thử `POST /api/v1/auth/user/signin`, rồi `POST /api/v1/app-settings {"invite_only_signup": true}` (`controllers/org-users.controller.ts`).
Không dùng `NC_ADMIN_PASSWORD`: `helpers/initAdminFromEnv.ts` đặt lại mật khẩu theo biến mỗi lần khởi động. Giấy phép: `LICENSE.md` (Sustainable Use License 1.0).
