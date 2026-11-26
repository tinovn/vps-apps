---
name: install-app
description: Cài Excalidraw (Docker, image chính thức build từ nhánh release, commit b2b2815) lên VPS Ubuntu của khách Tino, đặt mật khẩu HTTP Basic qua Caddy vì ứng dụng không có đăng nhập.
metadata:
  repo: excalidraw/excalidraw
  ref: b2b2815954f6561f0980bef8997750dabec16e87
  category: team
  title: Excalidraw
  summary_vi: Bảng vẽ phác thảo kiểu vẽ tay để minh hoạ ý tưởng, sơ đồ, giao diện nhanh cùng nhóm.
  min_cpu: 1
  min_ram_mb: 512
  min_disk_gb: 5
  os: ubuntu-24.04
  port: 8080
  healthcheck: /
  license: MIT
---

# Excalidraw

Script cài: `app.sh` + `lib/install.sh` → `install.sh`. Dự án không gắn tag cho image: `.github/workflows/publish-docker.yml` chỉ đẩy
`excalidraw/excalidraw:latest` khi nhánh `release` đổi. `ref` = commit `b2b2815` của lần đẩy thành công gần nhất (06/05/2026, khớp thời điểm
digest `sha256:f7ee19…`); image ghim theo digest đó. Ứng dụng tĩnh (nginx), không có tài khoản: `APP_AUTH=basic`, Caddy hỏi admin / mật khẩu.
