---
name: install-app
description: Cài Node-RED 5.0.9 (Docker) lên VPS Ubuntu của khách Tino, bật đăng nhập trình soạn thảo (adminAuth) rồi mới mở HTTPS qua Caddy.
metadata:
  repo: node-red/node-red
  ref: df0a87cce1a243e21a2e0eb0fdbdbb8c4732392f
  category: automation
  title: Node-RED
  summary_vi: Kéo thả các khối để nối thiết bị, API và dịch vụ thành luồng tự động hoá.
  min_cpu: 1
  min_ram_mb: 512
  min_disk_gb: 5
  os: ubuntu-24.04
  port: 1880
  healthcheck: /
  license: Apache-2.0
---

# Node-RED

Script cài: `app.sh` + `lib/install.sh` → `install.sh`. `ref` = commit của tag `5.0.9`; image `nodered/node-red` (repo
node-red/node-red-docker, tag `v5.0.9`) ghim theo digest. `/data/settings.js` = `settings.js` mặc định của gói node-red trong image
+ `adminAuth` (hash bcrypt bằng `bcryptjs` của node-red, mật khẩu qua biến môi trường) + `credentialSecret` từ `.env`.
Đăng nhập thử: `POST /auth/token` (`@node-red/editor-api/lib/auth`, client `node-red-admin`).
