APP_VERSION=1.19.0
IMAGE='mintplexlabs/anythingllm:1.19.0@sha256:daf5a6ae9d363ed578e7d41e2d0668c7eaa604bd90b0ff27435f893b0906833e'
WAIT_SECS=600
APP_NOTE='Đăng nhập rồi chọn nhà cung cấp LLM (OpenAI, Gemini, Ollama…) và nhập API key trong phần cài đặt.'

app_files() {
  secret JWT_SECRET 48
  secret SIG_KEY 48
  secret SIG_SALT 48
  # image chạy bằng uid 1000; storage/.env là nơi ứng dụng lưu cấu hình LLM chọn trên giao diện (theo docker/HOW_TO_USE_DOCKER.md)
  install -d -m 755 -o 1000 -g 1000 "$APP_DIR/storage"
  [ -e "$APP_DIR/storage/.env" ] || install -m 600 -o 1000 -g 1000 /dev/null "$APP_DIR/storage/.env"
  cat > "$APP_DIR/compose.yaml" <<EOF
services:
  anythingllm:
    image: $IMAGE
    container_name: anythingllm
    restart: unless-stopped
    # Chromium của trình thu thập website cần SYS_ADMIN (như hướng dẫn chính thức)
    cap_add:
      - SYS_ADMIN
    environment:
      STORAGE_DIR: /app/server/storage
      SERVER_PORT: "3001"
      JWT_SECRET: \${JWT_SECRET}
      SIG_KEY: \${SIG_KEY}
      SIG_SALT: \${SIG_SALT}
      DISABLE_TELEMETRY: "true"
    volumes:
      - ./storage:/app/server/storage
      - ./storage/.env:/app/server/.env
    ports:
      - "127.0.0.1:$APP_PORT:3001"
EOF
}

# Bật chế độ nhiều người dùng với tài khoản quản trị (API như trang Cài đặt → Bảo mật), rồi đăng nhập thử.
app_setup() {
  local creds
  creds=$(jq -n --arg u "$ADMIN_USER" --arg p "$ADMIN_PW" '{username: $u, password: $p}')
  if [ "$(api GET /api/system/multi-user-mode | jq -r .multiUserMode)" != true ]; then
    api POST /api/system/enable-multi-user -H 'Content-Type: application/json' --data-binary @- <<<"$creds" |
      jq -e '.success == true' >/dev/null
  fi
  api POST /api/request-token -H 'Content-Type: application/json' --data-binary @- <<<"$creds" |
    jq -e '.valid == true and .user.role == "admin"' >/dev/null
}
