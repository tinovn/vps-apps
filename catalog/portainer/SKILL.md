---
name: install-app
description: Cài Portainer CE 2.45.3 (Docker) lên VPS Ubuntu của khách Tino, tạo admin bằng --admin-password-file rồi mới mở HTTPS qua Caddy.
metadata:
  repo: portainer/portainer
  ref: 0fa764dc81c76bb7914d65d8e62b026d7c746899
  category: dev
  title: Portainer
  summary_vi: Quản lý container Docker trên VPS bằng giao diện web — chạy, xem log, cập nhật.
  min_cpu: 1
  min_ram_mb: 1024
  min_disk_gb: 10
  os: ubuntu-24.04
  port: 9000
  healthcheck: /api/system/status
  license: Zlib
---

# Portainer

Script cài: `app.sh` + `lib/install.sh` → `install.sh`. `ref` = commit của tag `2.45.3` (LTS); image `portainer/portainer-ce:2.45.3`
ghim theo digest. Admin (`admin`) tạo từ `--admin-password-file` ở lần chạy đầu (`api/cmd/portainer/main.go`: đã có admin thì bỏ qua),
`-H unix:///var/run/docker.sock` tạo sẵn môi trường local; đăng nhập thử `POST /api/auth` (`api/http/handler/auth/authenticate.go`).
`/api/system/status` là route công khai (`api/http/handler/system/handler.go`).
