APP_VERSION=6.2.0
IMAGE='listmonk/listmonk:v6.2.0@sha256:f535d59e14991337a9f2d570273685378ae86b0d7698c3e00da444e3bc205286'
DB_IMAGE='postgres:17.12-alpine@sha256:a77aa70e641402a21411b92b721c58d10f23b50ae5fdd2333efd22d166e1e5f7'
APP_NOTE='Trang quản trị ở /admin. Khai báo máy chủ SMTP (Settings → SMTP) thì mới gửi được email.'

app_files() {
  secret DB_PASSWORD
  envset ADMIN_PW "$ADMIN_PW"
  cat > "$APP_DIR/compose.yaml" <<EOF
services:
  db:
    image: $DB_IMAGE
    restart: unless-stopped
    environment:
      POSTGRES_DB: listmonk
      POSTGRES_USER: listmonk
      POSTGRES_PASSWORD: \${DB_PASSWORD}
    volumes:
      - ./db:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U listmonk -d listmonk"]
      interval: 5s
      retries: 60
  app:
    image: $IMAGE
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
    # như docker-compose.yml của listmonk: --install --idempotent chỉ tạo bảng + quản trị (LISTMONK_ADMIN_*) khi CSDL trống
    command: [sh, -c, "./listmonk --install --idempotent --yes --config '' && ./listmonk --upgrade --yes --config '' && ./listmonk --config ''"]
    environment:
      LISTMONK_app__address: 0.0.0.0:9000
      LISTMONK_db__host: db
      LISTMONK_db__port: "5432"
      LISTMONK_db__user: listmonk
      LISTMONK_db__password: \${DB_PASSWORD}
      LISTMONK_db__database: listmonk
      LISTMONK_db__ssl_mode: disable
      LISTMONK_db__max_open: "25"
      LISTMONK_db__max_idle: "25"
      LISTMONK_db__max_lifetime: 300s
      LISTMONK_ADMIN_USER: $ADMIN_USER
      LISTMONK_ADMIN_PASSWORD: \${ADMIN_PW}
      TZ: Asia/Ho_Chi_Minh
    volumes:
      - ./uploads:/listmonk/uploads
    ports:
      - "127.0.0.1:$APP_PORT:9000"
EOF
}

app_setup() {
  local url=${TINO_URL%/} code
  # app.root_url nằm trong bảng settings (biến môi trường không ghi đè được): đặt theo tên miền rồi khởi động lại
  if [ "$(compose exec -T db psql -U listmonk -d listmonk -tAc "SELECT value #>> '{}' FROM settings WHERE key = 'app.root_url'")" != "$url" ]; then
    compose exec -T db psql -U listmonk -d listmonk -qc "UPDATE settings SET value = to_jsonb('$url'::text) WHERE key = 'app.root_url'"
    compose restart app
    wait_http "$APP_HEALTH" 120 || die 'listmonk không khởi động lại được sau khi đặt root_url.'
  fi
  # đăng nhập thử qua form /admin/login: đúng → 302, sai → 200 kèm thông báo (mật khẩu qua stdin, máy chủ tự bỏ \n cuối)
  code=$(curl -s -o /dev/null -w '%{http_code}' --data-urlencode "username=$ADMIN_USER" --data-urlencode 'password@-' \
    "http://127.0.0.1:$APP_PORT/admin/login" <<<"$ADMIN_PW")
  [ "$code" = 302 ] || die "Đăng nhập thử listmonk thất bại (HTTP $code)."
}
