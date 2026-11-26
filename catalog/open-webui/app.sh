APP_VERSION=0.13.3
IMAGE='ghcr.io/open-webui/open-webui:v0.13.3@sha256:46b59158e6558eeb980bc828e0f1b30238ad24d82ed84d5e5eda1dab2a082f14'
ADMIN_USER="admin@$TINO_HOST"  # Open WebUI đăng nhập bằng email
WAIT_SECS=600  # lần đầu tải mô hình embedding cho RAG
APP_NOTE='Vào Cài đặt quản trị → Kết nối để thêm API key (OpenAI, Gemini…) hoặc địa chỉ Ollama. Đăng ký tự do đang tắt.'

app_files() {
  secret WEBUI_SECRET_KEY 64
  envset ADMIN_PW "$ADMIN_PW"
  cat > "$APP_DIR/compose.yaml" <<EOF
services:
  open-webui:
    image: $IMAGE
    container_name: open-webui
    restart: unless-stopped
    environment:
      WEBUI_URL: ${TINO_URL%/}
      WEBUI_SECRET_KEY: \${WEBUI_SECRET_KEY}
      WEBUI_SESSION_COOKIE_SECURE: "true"
      ENABLE_SIGNUP: "false"
      # tạo quản trị lúc khởi động khi chưa có người dùng nào, rồi tự tắt đăng ký
      WEBUI_ADMIN_EMAIL: $ADMIN_USER
      WEBUI_ADMIN_PASSWORD: \${ADMIN_PW}
      WEBUI_ADMIN_NAME: Admin
    volumes:
      - ./data:/app/backend/data
    ports:
      - "127.0.0.1:$APP_PORT:8080"
EOF
}

app_setup() {
  jq -n --arg e "$ADMIN_USER" --arg p "$ADMIN_PW" '{email: $e, password: $p}' |
    api POST /api/v1/auths/signin -H 'Content-Type: application/json' --data-binary @- |
    jq -e '.role == "admin" and (.token | length > 0)' >/dev/null
}
