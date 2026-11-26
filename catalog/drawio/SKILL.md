---
name: install-app
description: Cài draw.io 32.6.10 (Docker, image jgraph/drawio trên Tomcat) lên VPS Ubuntu của khách Tino, đặt mật khẩu HTTP Basic qua Caddy vì ứng dụng không có đăng nhập.
metadata:
  repo: jgraph/drawio
  ref: c72c9a98b7a6ce392556ed04c05e0ff19f43f5c3
  category: team
  title: draw.io
  summary_vi: Vẽ sơ đồ quy trình, sơ đồ mạng, tổ chức, UML ngay trên trình duyệt — bản tự host của diagrams.net.
  min_cpu: 1
  min_ram_mb: 1024
  min_disk_gb: 5
  os: ubuntu-24.04
  port: 8080
  healthcheck: /
  license: Apache-2.0
---

# draw.io

Script cài: `app.sh` + `lib/install.sh` → `install.sh`. `ref` = commit của tag `v32.6.10`; image `jgraph/drawio:32.6.10` ghim digest
(build từ https://github.com/jgraph/docker-drawio, webapp ở `/`, `DRAWIO_SERVER_URL` = URL công khai có `/` cuối). Ứng dụng không có
tài khoản: `APP_AUTH=basic`, Caddy hỏi admin / mật khẩu.
