APP_VERSION=1.12.2
# bản full: gộp sẵn SearXNG (nghe 8080 trong container, không publish); image ~3,9 GB nén
IMAGE='itzcrazykns1337/vane:v1.12.2@sha256:61f2bbf3386ff3df08911fb3de0e1893b04702a4d49ef13fbadbda937b47ab7c'
APP_AUTH=basic  # Vane không có đăng nhập
WAIT_SECS=420
APP_NOTE='Lần đầu mở trang, chọn nhà cung cấp và nhập khoá API mô hình (OpenAI, Anthropic, Gemini, Ollama…) trong màn hình thiết lập.'

app_files() {
  cat > "$APP_DIR/compose.yaml" <<EOF
services:
  vane:
    image: $IMAGE
    container_name: vane
    restart: unless-stopped
    volumes:
      - data:/home/vane/data
      - uploads:/home/vane/uploads
    ports:
      - "127.0.0.1:$APP_PORT:3000"
volumes:
  data:
  uploads:
EOF
}
