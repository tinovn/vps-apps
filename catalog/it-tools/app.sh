APP_VERSION=2024.10.22-7ca5933
IMAGE='corentinth/it-tools:2024.10.22-7ca5933@sha256:8b8128748339583ca951af03dfe02a9a4d7363f61a216226fc28030731a5a61f'
APP_AUTH=basic  # trang tĩnh không có đăng nhập: Caddy hỏi tài khoản

app_files() {
  cat > "$APP_DIR/compose.yaml" <<EOF
services:
  it-tools:
    image: $IMAGE
    restart: unless-stopped
    ports:
      - "127.0.0.1:$APP_PORT:80"
EOF
}
