APP_VERSION=13.3.1
IMAGE='grafana/grafana:13.3.1@sha256:0615ec4fbd4072004b7d86b46ded63013a74b7d6eb1119273dd89e8fa25c13cf'
APP_NOTE='Đăng ký tự do đang tắt; thêm nguồn dữ liệu (Prometheus, MySQL…) trong Connections → Data sources.'

app_files() {
  secret SECRET_KEY 40
  envset ADMIN_PW "$ADMIN_PW"
  # GF_SECURITY_ADMIN_* chỉ có tác dụng lần chạy đầu (Grafana tạo admin khi CSDL còn trống), chạy lại không đổi mật khẩu.
  cat > "$APP_DIR/compose.yaml" <<EOF
services:
  grafana:
    image: $IMAGE
    container_name: grafana
    restart: unless-stopped
    environment:
      GF_SERVER_ROOT_URL: $TINO_URL
      GF_SECURITY_ADMIN_USER: $ADMIN_USER
      GF_SECURITY_ADMIN_PASSWORD: \${ADMIN_PW}
      GF_SECURITY_SECRET_KEY: \${SECRET_KEY}
      GF_SECURITY_COOKIE_SECURE: "true"
      GF_USERS_ALLOW_SIGN_UP: "false"
      GF_ANALYTICS_REPORTING_ENABLED: "false"
    volumes:
      # named volume: image chạy uid 472, thư mục bind-mount của root không ghi được
      - grafana-data:/var/lib/grafana
    ports:
      - "127.0.0.1:$APP_PORT:3000"
volumes:
  grafana-data:
EOF
}

app_setup() {
  # đăng nhập thử bằng Basic auth (mật khẩu qua stdin của curl); không thử lại để tránh khoá đăng nhập do sai nhiều lần
  api GET /api/user -K - <<<"user = \"$ADMIN_USER:$ADMIN_PW\"" | jq -e '.isGrafanaAdmin == true' >/dev/null
}
