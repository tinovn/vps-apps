---
name: install-app
description: Cài Keycloak 26.8.2 (Docker, PostgreSQL 17) lên VPS Ubuntu của khách Tino, tạo quản trị chính thức của realm master qua admin API rồi mới mở HTTPS qua Caddy.
metadata:
  repo: keycloak/keycloak
  ref: e514445f9dcdabc5bdcf67cab56c1e49655de067
  category: data
  title: Keycloak
  summary_vi: Đăng nhập một lần (SSO) và quản lý tài khoản người dùng cho các ứng dụng của bạn.
  min_cpu: 1
  min_ram_mb: 2048
  min_disk_gb: 10
  os: ubuntu-24.04
  port: 8080
  healthcheck: /realms/master
  license: Apache-2.0
---

# Keycloak

`ref` = commit của tag `26.8.2`; image `quay.io/keycloak/keycloak` ghim theo digest, chạy `start` với `KC_HOSTNAME` = URL đầy đủ, `KC_PROXY_HEADERS=xforwarded`, `KC_HTTP_ENABLED=true` (`docs/guides/server/hostname.adoc`, `reverseproxy.adoc`, `containers.adoc`).
`KC_BOOTSTRAP_ADMIN_*` chỉ tạo quản trị tạm khi khởi tạo realm master (`quarkus/runtime/.../QuarkusKeycloakApplication.java`); app_setup dùng nó gọi admin REST API tạo `admin` (vai trò realm `admin`), đăng nhập thử bằng password grant của `admin-cli`, rồi xoá quản trị tạm.
`mem_limit` = 2/3 RAM VPS vì image đặt heap 70% giới hạn RAM container, cộng ~300 MB ngoài heap (`containers.adoc`).
