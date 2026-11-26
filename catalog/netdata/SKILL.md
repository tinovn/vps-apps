---
name: install-app
description: Cài Netdata 2.12.3 (Docker, mạng host, chỉ nghe 127.0.0.1) lên VPS Ubuntu của khách Tino, mở HTTPS qua Caddy có hỏi mật khẩu.
metadata:
  repo: netdata/netdata
  ref: 0549a74d8493c32dcea87506ff8de6555ddf6905
  category: monitoring
  title: Netdata
  summary_vi: Giám sát VPS theo thời gian thực — CPU, RAM, ổ đĩa, mạng, container — với cảnh báo dựng sẵn.
  min_cpu: 1
  min_ram_mb: 1024
  min_disk_gb: 10
  os: ubuntu-24.04
  port: 19999
  healthcheck: /api/v1/info
  license: GPL-3.0-or-later
---

# Netdata

Script cài: `app.sh` + `lib/install.sh` → `install.sh`. `ref` = commit của tag `v2.12.3`; image ghim theo digest; compose theo packaging/docker/README.md.
Dashboard cục bộ không có tài khoản: Caddy hỏi Basic auth (`APP_AUTH=basic`). Web server ép nghe 127.0.0.1 bằng `-W set web "bind to"` (src/daemon/main.c, src/web/server/README.md);
`DO_NOT_TRACK=1` tắt thống kê ẩn danh (packaging/docker/run.sh); healthcheck `/api/v1/info` như packaging/docker/health.sh.
