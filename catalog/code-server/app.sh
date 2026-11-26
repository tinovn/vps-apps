APP_VERSION=4.145.2
IMAGE='codercom/code-server:4.145.2@sha256:09565f9e07f5624554e295e8bab0e2fec4a7c533eb3cff459ed6596a4d3d7c1c'
APP_NOTE='code-server chỉ hỏi mật khẩu, không có tên đăng nhập. Terminal và mã nguồn nằm trong container (thư mục /home/coder), không phải trên VPS.'

app_files() {
  envset ADMIN_PW "$ADMIN_PW"
  cat > "$APP_DIR/compose.yaml" <<EOF
services:
  code-server:
    image: $IMAGE
    restart: unless-stopped
    environment:
      PASSWORD: \${ADMIN_PW}
    volumes:
      # volume có tên: giữ quyền user coder (1000) của image
      - home:/home/coder
    ports:
      - "127.0.0.1:$APP_PORT:8080"
volumes:
  home:
EOF
}

# Mật khẩu lấy từ biến PASSWORD. Đăng nhập thử qua form /login: đúng → 302, sai → 200 kèm thông báo
# (mật khẩu qua stdin; code-server trim nên \n cuối không ảnh hưởng).
app_setup() {
  local code
  code=$(curl -s -o /dev/null -w '%{http_code}' --data-urlencode 'password@-' "http://127.0.0.1:$APP_PORT/login" <<<"$ADMIN_PW")
  [ "$code" = 302 ] || die "Đăng nhập thử code-server thất bại (HTTP $code)."
}
