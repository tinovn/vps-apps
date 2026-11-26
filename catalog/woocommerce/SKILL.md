---
name: install-app
description: Cài WordPress 7.1.4 kèm WooCommerce 11.3.0 (Docker, MariaDB 11.8) lên VPS Ubuntu của khách Tino, tạo quản trị bằng wp-cli rồi mới mở HTTPS qua Caddy.
metadata:
  repo: woocommerce/woocommerce
  ref: 74a33ab397bdbfd9dff295bd644c6c818cd5cdf4
  category: web
  title: WooCommerce
  summary_vi: Cửa hàng bán hàng online trên WordPress — sản phẩm, giỏ hàng, thanh toán, vận chuyển.
  min_cpu: 1
  min_ram_mb: 2048
  min_disk_gb: 15
  os: ubuntu-24.04
  port: 8080
  healthcheck: /wp-login.php
  license: GPL-3.0
---

# WooCommerce

Dùng lại khuôn `catalog/wordpress/app.sh` (`#@use wordpress`), thêm `wp plugin install woocommerce --version=11.3.0 --activate`.
`ref` = commit của tag `11.3.0` trong woocommerce/woocommerce; plugin tải từ wordpress.org đúng bản đó.
