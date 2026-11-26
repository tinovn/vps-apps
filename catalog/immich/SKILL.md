---
name: install-app
description: Cài Immich 3.4.1 (Docker, machine learning, PostgreSQL VectorChord, Valkey) lên VPS Ubuntu của khách Tino, tạo admin qua API rồi mới mở HTTPS qua Caddy.
metadata:
  repo: immich-app/immich
  ref: 22b95194c80a2f2e6201093916b6c8c3d6d271dd
  category: media
  title: Immich
  summary_vi: Kho ảnh và video riêng như Google Photos — tự sao lưu từ điện thoại, nhận diện khuôn mặt, tìm ảnh.
  min_cpu: 2
  min_ram_mb: 6144
  min_disk_gb: 40
  os: ubuntu-24.04
  port: 2283
  healthcheck: /api/server/ping
  license: AGPL-3.0
---

# Immich

`ref` = commit của tag `v3.4.1`; compose dựng theo `docker/docker-compose.yml` + `docker/example.env` của tag (trùng asset phát hành), mọi image ghim digest, cổng chỉ ở 127.0.0.1.
Yêu cầu theo `docs/docs/install/requirements.md`: RAM tối thiểu 6 GB (4 GB chỉ khi tắt machine learning), 2 nhân, CPU amd64 phải có x86-64-v2 (script kiểm SSE4.2/POPCNT).
Admin: `POST /api/auth/admin-sign-up` khi `GET /api/server/config` có `isInitialized=false` (`server/src/controllers/auth.controller.ts`, `services/server.service.ts`), đăng nhập thử `POST /api/auth/login` (`isAdmin`).
