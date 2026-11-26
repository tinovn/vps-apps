---
name: install-app
description: Cài MaxKB 2.10.8 LTS (Docker all-in-one) lên VPS Ubuntu của khách Tino, đổi mật khẩu admin mặc định qua API trên 127.0.0.1 rồi mới mở HTTPS qua Caddy.
metadata:
  repo: 1Panel-dev/MaxKB
  ref: 792a525c5a78e42bf04b91c251f747a0bc3e8517
  category: ai
  title: MaxKB
  summary_vi: Dựng chatbot hỏi đáp trên tài liệu của doanh nghiệp (RAG), gắn vào website hoặc dùng nội bộ.
  min_cpu: 2
  min_ram_mb: 2048
  min_disk_gb: 20
  os: ubuntu-24.04
  port: 8080
  healthcheck: /admin/
  license: GPL-3.0-only
---

# MaxKB

Script cài: `app.sh` + `lib/install.sh` → `install.sh`. `ref` = commit của tag `v2.10.8-lts`; image `1panel/maxkb:v2.10.8-lts` (all-in-one, `installer/Dockerfile`) ghim digest.
Tài khoản mặc định `admin` / `MaxKB@123..` (README) được đổi qua `POST /admin/api/user/login` rồi `POST /admin/api/user/current/reset_password` (`apps/users/urls.py`, `apps/users/serializers/user.py`: mật khẩu 6–20 ký tự, đủ 4 loại ký tự), sau đó đăng nhập thử bằng mật khẩu mới.
