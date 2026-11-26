---
name: install-app
description: Cài Jenkins LTS 2.580.2 (Docker, JDK 21) lên VPS Ubuntu của khách Tino, tạo quản trị bằng init.groovy.d rồi mới mở HTTPS qua Caddy.
metadata:
  repo: jenkinsci/jenkins
  ref: ea3f958268fe87ed86a5d1c2d90c5a99426b97ce
  category: dev
  title: Jenkins
  summary_vi: Máy chủ CI/CD tự động build, test, triển khai mã nguồn theo pipeline.
  min_cpu: 1
  min_ram_mb: 2048
  min_disk_gb: 20
  os: ubuntu-24.04
  port: 8080
  healthcheck: /login
  license: MIT
---

# Jenkins

Script cài: `app.sh` + `lib/install.sh` → `install.sh`. `ref` = commit của tag `jenkins-2.580.2` (LTS mới nhất); image
`jenkins/jenkins:2.580.2-lts-jdk21` ghim theo digest. `-Djenkins.install.runSetupWizard=false`; script `init.groovy.d` tạo quản trị
(`HudsonPrivateSecurityRealm(false).createAccount`, `FullControlOnceLoggedInAuthorizationStrategy` không cho anonymous đọc,
`JenkinsLocationConfiguration.setUrl`) — API ở `core/src/main/java/hudson/security/`. Đăng nhập thử `GET /whoAmI/api/json` bằng Basic auth.
