APP_VERSION=3.1.1
IMAGE='gotify/server:3.1.1@sha256:44fc5bbd1c0618878e33073d38c2c13126b48f245c3fe12236b1da48eb203b86'
APP_NOTE='Ứng dụng Gotify trên điện thoại: thêm máy chủ bằng địa chỉ HTTPS của dịch vụ và đăng nhập bằng tài khoản quản trị. Đăng ký tự do đang tắt.'

app_files() {
  envset ADMIN_PW "$ADMIN_PW"
  cat > "$APP_DIR/compose.yaml" <<EOF
services:
  gotify:
    image: $IMAGE
    container_name: gotify
    restart: unless-stopped
    environment:
      # Chỉ dùng khi cơ sở dữ liệu chưa có người dùng nào (lần chạy đầu).
      GOTIFY_DEFAULTUSER_NAME: $ADMIN_USER
      GOTIFY_DEFAULTUSER_PASS: \${ADMIN_PW}
      GOTIFY_REGISTRATION: "false"
      GOTIFY_SERVER_SECURECOOKIE: "true"
    volumes:
      - ./data:/app/data
    ports:
      - "127.0.0.1:$APP_PORT:80"
EOF
}

# đăng nhập thử bằng Basic auth (mật khẩu đi qua stdin của curl)
app_setup() {
  api GET /current/user -K - <<<"user = \"$ADMIN_USER:$ADMIN_PW\"" | jq -e '.admin == true' >/dev/null
}
