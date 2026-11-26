---
name: install-app
description: Cài PrestaShop 9.2.1 (Docker, PHP 8.5, MariaDB 11.8) lên VPS Ubuntu của khách Tino, cài tự động kèm tài khoản quản trị rồi mới mở HTTPS qua Caddy.
metadata:
  repo: PrestaShop/PrestaShop
  ref: 384f714c3fc1329b97a581d0bf79ec330b4078f6
  category: web
  title: PrestaShop
  summary_vi: Website bán hàng đầy đủ — sản phẩm, giỏ hàng, đơn hàng, thanh toán, vận chuyển.
  min_cpu: 1
  min_ram_mb: 2048
  min_disk_gb: 20
  os: ubuntu-24.04
  port: 8080
  healthcheck: /
  license: OSL-3.0
---

# PrestaShop

Script cài: `app.sh` + `lib/install.sh` → `install.sh`. `ref` = commit của tag `9.2.1`; image `prestashop/prestashop:9.2.1-apache`
(= 9.2.1-8.5, PHP khuyến nghị) ghim theo digest. Cài bằng `PS_INSTALL_AUTO=1` của image (`base/config_files/docker_run.sh` ở
PrestaShop/docker: `index_cli.php --password=$ADMIN_PASSWD --email=$ADMIN_MAIL --ssl=$PS_ENABLE_SSL`), thư mục quản trị đổi tên qua
`PS_FOLDER_ADMIN`; `PS_TRUSTED_PROXIES` từ `app/config/config.yml`. Đăng nhập thử bằng `password_verify` với `ps_employee`.
