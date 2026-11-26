---
name: install-app
description: Cài Docmost 0.97.0 (Docker, PostgreSQL 18, Redis) lên VPS Ubuntu của khách Tino, tạo workspace và quản trị qua API setup rồi mới mở HTTPS qua Caddy.
metadata:
  repo: docmost/docmost
  ref: 6d117f8c52e54e810d5931f153eb2d31c904efb3
  category: team
  title: Docmost
  summary_vi: Soạn tài liệu và wiki cho nhóm như Notion/Confluence riêng — cùng sửa trực tiếp, phân quyền theo không gian.
  min_cpu: 1
  min_ram_mb: 1024
  min_disk_gb: 10
  os: ubuntu-24.04
  port: 3000
  healthcheck: /api/health
  license: AGPL-3.0
---

# Docmost

Script cài: `app.sh` + `lib/install.sh` → `install.sh`. `ref` = commit của tag `v0.97.0`; image `docmost/docmost:0.97.0` ghim digest,
compose theo `docker-compose.yml` của repo. Quản trị: `POST /api/auth/setup` (`apps/server/src/core/auth/auth.controller.ts`,
`dto/create-admin-user.dto.ts`; `SetupGuard` chỉ cho khi chưa có workspace) tạo workspace + chủ sở hữu; đăng nhập thử `POST /api/auth/login`.
Giấy phép AGPL-3.0, riêng thư mục `ee/` theo giấy phép doanh nghiệp của Docmost.
