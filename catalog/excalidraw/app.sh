APP_VERSION=b2b2815
# Dự án chỉ phát hành image dạng :latest (workflow publish-docker.yml, nhánh release); ghim theo digest của bản build
# từ commit b2b2815 (06/05/2026).
IMAGE='excalidraw/excalidraw:latest@sha256:f7ee194addd607bf831d2af0f0a34463dd4225e426cf35199ef0b12a803398e9'
APP_AUTH=basic  # Excalidraw không có đăng nhập
APP_NOTE='Bản vẽ lưu trong trình duyệt của từng người (nên xuất tệp .excalidraw để sao lưu); cộng tác trực tiếp và chia sẻ liên kết đi qua máy chủ excalidraw.com (mã hoá đầu cuối).'

app_files() {
  cat > "$APP_DIR/compose.yaml" <<EOF
services:
  excalidraw:
    image: $IMAGE
    restart: unless-stopped
    ports:
      - "127.0.0.1:$APP_PORT:80"
EOF
}
