---
name: install-app
description: Cài OpenClaw 2026.11.4 (Docker, gateway + Control UI) lên VPS Ubuntu của khách Tino, đăng nhập qua Caddy (trusted-proxy) rồi mới mở HTTPS.
metadata:
  repo: openclaw/openclaw
  ref: d843d6af39a42cd3c30084edbeabeece732fd93a
  category: ai
  title: OpenClaw
  summary_vi: Trợ lý AI cá nhân chạy 24/7, trò chuyện qua Telegram, Zalo và trang điều khiển web.
  min_cpu: 1
  min_ram_mb: 2048
  min_disk_gb: 20
  os: ubuntu-24.04
  port: 18789
  healthcheck: /healthz
  license: MIT
---

# OpenClaw

Script cài: `app.sh` + `lib/install.sh` → `install.sh`. `ref` = commit của tag `v2026.11.4`; image `ghcr.io/openclaw/openclaw` ghim theo digest.
`gateway.auth.mode: trusted-proxy`: Caddy hỏi admin/mật khẩu rồi gửi `X-Forwarded-User`; `trustedProxies` chỉ có cổng mạng compose, `deviceAutoApprove` + `identityScopes` cho đúng người dùng đó (docs/gateway/trusted-proxy-auth.md, docs/web/control-ui/connect-and-pair.md, src/gateway/server/ws-connection/connect-pairing-approval-plan.ts).
Không bật kênh nào; DM mặc định `pairing` (docs/channels/telegram.md). `/healthz` không cần đăng nhập (docs/gateway/health.md).
