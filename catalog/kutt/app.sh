APP_VERSION=3.2.6
IMAGE='kutt/kutt:v3.2.6@sha256:fa3d24a89b04e0feb542ed7d3c77993d58dbcc1406e5291a369595d543886146'
ADMIN_USER="admin@$TINO_HOST"  # Kutt đăng nhập bằng email
APP_NOTE='Đăng ký tự do đang tắt; quản trị thêm người dùng trong trang Admin. Link rút gọn dùng tên miền của VPS.'

app_files() {
  secret JWT_SECRET 64
  cat > "$APP_DIR/compose.yaml" <<EOF
services:
  kutt:
    image: $IMAGE
    restart: unless-stopped
    environment:
      DB_FILENAME: /var/lib/kutt/data.sqlite
      JWT_SECRET: \${JWT_SECRET}
      DEFAULT_DOMAIN: $TINO_HOST
      DISALLOW_REGISTRATION: "true"
      DISALLOW_ANONYMOUS_LINKS: "true"
    volumes:
      - ./data:/var/lib/kutt
    ports:
      - "127.0.0.1:$APP_PORT:3000"
EOF
}

# kutt_auth login|create-admin: gửi email + mật khẩu quản trị dạng JSON
kutt_auth() {
  jq -n --arg e "$ADMIN_USER" --arg p "$ADMIN_PW" '{email: $e, password: $p}' |
    api POST "/api/auth/$1" -H 'Content-Type: application/json' -H 'Accept: application/json' --data-binary @-
}

# Kutt 3 tạo admin đầu tiên bằng POST /api/auth/create-admin (chỉ khi chưa có người dùng nào, như trang tạo admin); rồi đăng nhập thử.
app_setup() {
  if ! kutt_auth login 2>/dev/null | jq -e '.token' >/dev/null; then
    kutt_auth create-admin >/dev/null
    kutt_auth login | jq -e '.token' >/dev/null
  fi
}
