---
name: install-app
description: Cài Nextcloud 35.0.3 (Docker, PostgreSQL 18, Redis) lên VPS Ubuntu của khách Tino, image tự cài với tài khoản quản trị rồi mới mở HTTPS qua Caddy.
metadata:
  repo: nextcloud/server
  ref: 7764ef4927e5f85071e495ce7602ccd247bb6b30
  category: team
  title: Nextcloud
  summary_vi: Lưu trữ, đồng bộ và chia sẻ tệp như Google Drive riêng, kèm lịch, danh bạ, ứng dụng văn phòng.
  min_cpu: 1
  min_ram_mb: 2048
  min_disk_gb: 20
  os: ubuntu-24.04
  port: 8080
  healthcheck: /status.php
  license: AGPL-3.0
---

# Nextcloud

Script cài: `app.sh` + `lib/install.sh` → `install.sh`. `ref` = commit của tag `v35.0.3`; image `nextcloud:35.0.3-apache` ghim digest.
Quản trị tạo bởi entrypoint của image (`occ maintenance:install` khi có `NEXTCLOUD_ADMIN_USER/PASSWORD` + `POSTGRES_*`), xem
https://github.com/nextcloud/docker/blob/master/35/apache/entrypoint.sh; cron nền bằng container `/cron.sh` + `occ background:cron`;
đăng nhập thử qua OCS `/ocs/v2.php/cloud/user`.
