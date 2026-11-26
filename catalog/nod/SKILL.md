---
name: install-app
description: Cài Nod 0.9.7 (trợ lý AI cá nhân của n8n, Docker: server, PostgreSQL, trình duyệt, vùng làm việc) lên VPS Ubuntu của khách Tino, đăng nhập bằng access token, mở HTTPS qua Caddy.
metadata:
  repo: n8n-io/nod
  ref: 1128fcfd770d619f3391e0bd9f1ca2f9966f2be6
  category: ai
  title: Nod
  summary_vi: Trợ lý AI cá nhân của n8n có máy làm việc riêng, tự thao tác web, email, tài liệu và hỏi bạn trước khi làm việc quan trọng.
  min_cpu: 2
  min_ram_mb: 8192
  min_disk_gb: 50
  os: ubuntu-24.04
  port: 4310
  healthcheck: /
  license: Apache-2.0
---

# Nod

Script cài: `app.sh` + `lib/install.sh` → `install.sh`. `ref` = commit của tag `nod-v0.9.7`. n8n không phát hành image:
3 image `ghcr.io/tinovn/nod-{server,browser,workspace}` build bằng `images/nod/build.sh` từ đúng tag này, ghim theo digest.

`compose.yaml` theo `deployment/self-host/compose.yaml` của tag (giữ `cap_drop`, `read_only`, `mem_limit`, mạng internal,
dịch vụ `runtime` chỉ cho exec vào 2 container của Nod qua `docker-proxy.mjs`), bỏ `build:` và profile `https`: Caddy của
khung cấp HTTPS cho hostname VPS. Bí mật như `setup.sh` của họ: `NOD_AUTH_TOKEN`, `NOD_POSTGRES_PASSWORD` (≥ 43 ký tự
`[A-Za-z0-9_-]`), `NOD_VAULT_KEY` (`openssl rand -base64 32`).

Server chỉ nhận Host trùng `NOD_PUBLIC_URL` (khác thì 403) và `/api/*` cần `Authorization: Bearer <NOD_AUTH_TOKEN>`
(`src/server/access.ts`). Script chờ `/api/health` kèm Host và token như `deployment/self-host/healthcheck.mjs`;
`healthcheck` của danh mục là `/` (trang không cần token) cho bước tự kiểm của HostBill, bước này hỏi lại với Host công khai
khi 127.0.0.1 bị 403 (OTE 26/11 job 11). Một server = một
người; token là mật khẩu trong `/root/tino-app.txt`. Model (ChatGPT hoặc khoá API) khách tự kết nối trong Nod.
