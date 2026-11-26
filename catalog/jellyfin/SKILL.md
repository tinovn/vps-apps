---
name: install-app
description: Cài Jellyfin 12.4 (Docker) lên VPS Ubuntu của khách Tino, hoàn tất trình hướng dẫn lần đầu qua API rồi mới mở HTTPS qua Caddy.
metadata:
  repo: jellyfin/jellyfin
  ref: 83d0d0e7f76e23e2e085c8ff67d28b772d35967d
  category: media
  title: Jellyfin
  summary_vi: Máy chủ phim và nhạc riêng như Netflix tại nhà — xem trên TV, điện thoại, trình duyệt.
  min_cpu: 2
  min_ram_mb: 2048
  min_disk_gb: 20
  os: ubuntu-24.04
  port: 8096
  healthcheck: /System/Info/Public
  license: GPL-2.0
---

# Jellyfin

`ref` = commit của tag `v12.4`; image `jellyfin/jellyfin:12.4` ghim theo digest (`/config`, `/cache`, thư viện ở `/media`).
Admin: trình hướng dẫn `/Startup/Configuration`, `GET+POST /Startup/User`, `/Startup/RemoteAccess`, `/Startup/Complete` khi `/System/Info/Public` có `StartupWizardCompleted=false` (`Jellyfin.Api/Controllers/StartupController.cs`, `Auth/FirstTimeSetupPolicy/FirstTimeSetupHandler.cs`), đăng nhập thử `POST /Users/AuthenticateByName` (`Username`, `Pw`).
Sau đó thêm `172.16.0.0/12` vào `KnownProxies` rồi khởi động lại: không có thì mọi kết nối qua Caddy đến từ gateway docker = LAN, mà `POST /System/Restart` cho LAN gọi không cần đăng nhập (`SystemController.cs`, `LocalAccessOrRequiresElevationHandler.cs`, `ApiServiceCollectionExtensions.cs`).
