APP_VERSION=32.6.10
IMAGE='jgraph/drawio:32.6.10@sha256:44e9e4b43d92a0704ee67da3dcf0966272ce95543cd135025ff05515e1dfaa9c'
APP_AUTH=basic  # draw.io không có đăng nhập
APP_NOTE='Sơ đồ lưu ở máy người dùng (tải tệp .drawio) hoặc Google Drive / OneDrive / GitHub theo lựa chọn khi lưu; máy chủ không giữ bản vẽ.'

app_files() {
  cat > "$APP_DIR/compose.yaml" <<EOF2
services:
  drawio:
    image: $IMAGE
    restart: unless-stopped
    environment:
      DRAWIO_SERVER_URL: $TINO_URL
    ports:
      - "127.0.0.1:$APP_PORT:8080"
EOF2
}
