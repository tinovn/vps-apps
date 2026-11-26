APP_VERSION=1.19.0
ADMIN_USER="admin@$TINO_HOST"  # Dify đăng nhập bằng email
WAIT_SECS=900  # ~12 image lớn; lần đầu API chạy migration
APP_NOTE='Vào Cài đặt → Nhà cung cấp mô hình để thêm API key (OpenAI, Gemini…) trước khi tạo ứng dụng AI.'

# Dify dùng nguyên thư mục docker/ của repo ở đúng commit (compose + envs/*.defaults + nginx/ + ssrf_proxy/ …).
# Image theo tag của tệp upstream (không ghim digest). compose.yaml = docker-compose.yaml sửa cổng publish.
app_files() {
  local url=${TINO_URL%/} src="${APP_REPO#*/}-$APP_REF/docker" tmp k
  if [ "$(cat "$APP_DIR/.tino-ref" 2>/dev/null)" != "$APP_REF" ]; then
    tmp=$(mktemp -d)
    curl -fsSL "https://codeload.github.com/$APP_REPO/tar.gz/$APP_REF" | tar -xz -C "$tmp" "$src"
    cp -a "$tmp/$src/." "$APP_DIR/"
    rm -rf "$tmp"
    printf '%s\n' "$APP_REF" > "$APP_DIR/.tino-ref"
  fi
  # nginx (HTTP) và cổng debug plugin chỉ nghe 127.0.0.1; bỏ cổng HTTPS của nginx (Caddy lo TLS, 443 là của Caddy).
  # Không đặt EXPOSE_PLUGIN_DEBUGGING_PORT=127.0.0.1:5003: API đọc biến này là số (configs/feature, issue #39323).
  sed -e 's/- "\${EXPOSE_NGINX_PORT/- "127.0.0.1:${EXPOSE_NGINX_PORT/' \
    -e 's/- "\${EXPOSE_PLUGIN_DEBUGGING_PORT/- "127.0.0.1:${EXPOSE_PLUGIN_DEBUGGING_PORT/' \
    -e '/- "\${EXPOSE_NGINX_SSL_PORT/d' "$APP_DIR/docker-compose.yaml" > "$APP_DIR/compose.yaml"
  [ "$(grep -c '"127.0.0.1:\${EXPOSE_' "$APP_DIR/compose.yaml")" = 2 ] && ! grep -q 'EXPOSE_NGINX_SSL_PORT' "$APP_DIR/compose.yaml" ||
    die 'Dify: không sửa được cổng publish trong docker-compose.yaml của bản này.'

  # .env gốc (theo .env.example và README của docker/): hồ sơ dịch vụ, cổng, bí mật thay mặc định công khai, URL công khai
  envset COMPOSE_PROFILES weaviate,postgresql,collaboration
  envset EXPOSE_NGINX_PORT "$APP_PORT"
  grep -q '^DIFY_AGENT_LOCAL_SANDBOX_AUTH_TOKEN=.' "$APP_DIR/.env" || envset DIFY_AGENT_LOCAL_SANDBOX_AUTH_TOKEN "$(openssl rand -hex 32)"
  for k in DB_PASSWORD REDIS_PASSWORD PLUGIN_DAEMON_KEY PLUGIN_DIFY_INNER_API_KEY SANDBOX_API_KEY; do secret "$k" 48; done
  envset CODE_EXECUTION_API_KEY "$(envget SANDBOX_API_KEY)"
  for k in CONSOLE_API_URL CONSOLE_WEB_URL SERVICE_API_URL APP_API_URL APP_WEB_URL FILES_URL TRIGGER_URL; do envset "$k" "$url"; done
  envset ENDPOINT_URL_TEMPLATE "$url/e/{hook_id}"
  envset NEXT_PUBLIC_SOCKET_URL "wss://$TINO_HOST"
}

app_setup() {
  if [ "$(api GET /console/api/setup | jq -r .step)" != finished ]; then
    jq -n --arg e "$ADMIN_USER" --arg p "$ADMIN_PW" '{email: $e, name: "Admin", password: $p, language: "vi-VN"}' |
      api POST /console/api/setup -H 'Content-Type: application/json' --data-binary @- >/dev/null
  fi
  # trang đăng nhập gửi mật khẩu dạng base64 (decrypt_password_field)
  jq -n --arg e "$ADMIN_USER" --arg p "$ADMIN_PW" '{email: $e, password: ($p | @base64), remember_me: false}' |
    api POST /console/api/login -H 'Content-Type: application/json' --data-binary @- | jq -e '.result == "success"' >/dev/null
}
