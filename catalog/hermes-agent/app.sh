APP_VERSION=0.23.2
IMAGE='nousresearch/hermes-agent:v0.23.2@sha256:d6746a084e9341baada483e3d6210444d3c1aeb7c130f0915150065fb2851459'
APP_NOTE='Vào trang quản trị mục Keys nhập khoá API mô hình, mục Channels nối Telegram rồi khởi động lại gateway; người lạ nhắn bot phải được duyệt ở mục Pairing.'

# Như docker-compose.yml của dự án: mạng host, dashboard chỉ nghe 127.0.0.1. public_url khác loopback làm dashboard
# bật cổng đăng nhập (provider "basic" bằng tài khoản quản trị); X-Forwarded-* từ loopback (Caddy) được tin sẵn.
app_files() {
  secret DASH_SECRET 48
  envset ADMIN_PW "$ADMIN_PW"
  cat > "$APP_DIR/compose.yaml" <<EOF
services:
  hermes:
    image: $IMAGE
    container_name: hermes
    restart: unless-stopped
    network_mode: host
    command: ["gateway", "run"]
    environment:
      HERMES_DASHBOARD: "1"
      HERMES_DASHBOARD_HOST: 127.0.0.1
      HERMES_DASHBOARD_PORT: "$APP_PORT"
      HERMES_DASHBOARD_PUBLIC_URL: https://$TINO_HOST
      HERMES_DASHBOARD_BASIC_AUTH_USERNAME: $ADMIN_USER
      HERMES_DASHBOARD_BASIC_AUTH_PASSWORD: \${ADMIN_PW}
      HERMES_DASHBOARD_BASIC_AUTH_SECRET: \${DASH_SECRET}
    volumes:
      - ./data:/opt/data
EOF
}

app_setup() {
  api GET /api/status | jq -e '.auth_required == true and (.auth_providers | index("basic"))' >/dev/null \
    || die 'Dashboard Hermes chưa bật đăng nhập bằng mật khẩu.'
  jq -n --arg u "$ADMIN_USER" --arg p "$ADMIN_PW" '{provider: "basic", username: $u, password: $p}' \
    | api POST /auth/password-login -H 'Content-Type: application/json' --data-binary @- | jq -e '.ok == true' >/dev/null
}
