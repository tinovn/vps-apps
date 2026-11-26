#@use wordpress
APP_VERSION=11.3.0  # WooCommerce, cài trên WordPress 7.1.4 của khuôn wordpress
APP_NOTE='WooCommerce đã bật: vào trang quản trị (/wp-admin) → WooCommerce để thiết lập cửa hàng (tiền tệ, thanh toán, vận chuyển).'

wp_extra() {
  wp plugin is-installed woocommerce || wp plugin install woocommerce --version="$APP_VERSION" --activate
  wp plugin is-active woocommerce || wp plugin activate woocommerce
}
