APP_VERSION=2026.11.15-2d500cb6b
IMAGE='searxng/searxng:2026.11.15-2d500cb6b@sha256:932f69dca010db9880bddebb2171f05d8e1a25d04a59149ff65409993d680024'
APP_AUTH=basic  # SearXNG không có đăng nhập: Caddy hỏi tài khoản
APP_NOTE='Cấu hình ở /opt/searxng/config/settings.yml (sửa xong chạy: cd /opt/searxng && docker compose restart).'

app_files() {
  secret SEARXNG_SECRET 48
  # uid 977 = searxng trong image
  install -d -m 755 -o 977 -g 977 "$APP_DIR/config" "$APP_DIR/data"
  # settings.yml do entrypoint tạo từ mẫu lần đầu (secret_key ngẫu nhiên); SEARXNG_SECRET/BASE_URL/LIMITER ghi đè.
  # Limiter cần Valkey: tắt, trang đã có Basic auth của Caddy.
  cat > "$APP_DIR/compose.yaml" <<EOF
services:
  searxng:
    image: $IMAGE
    container_name: searxng
    restart: unless-stopped
    environment:
      SEARXNG_SECRET: \${SEARXNG_SECRET}
      SEARXNG_BASE_URL: $TINO_URL
      SEARXNG_LIMITER: "false"
    volumes:
      - ./config:/etc/searxng
      - ./data:/var/cache/searxng
    ports:
      - "127.0.0.1:$APP_PORT:8080"
EOF
}
