APP_VERSION=12.6.1
IMAGE='directus/directus:12.6.1@sha256:e1561b5e526e8e7a2ac19b7bb6eab63611dd84a862a8c45b864118768a2baff4'
DB_IMAGE='postgres:17.12-alpine@sha256:a77aa70e641402a21411b92b721c58d10f23b50ae5fdd2333efd22d166e1e5f7'
ADMIN_USER="admin@$TINO_HOST"  # Directus đăng nhập bằng email
APP_NOTE='Bản Core miễn phí của Directus giới hạn 3 tài khoản, 25 collection, 5 flow; cần nhiều hơn thì mua license key của Directus.'

app_files() {
  secret DB_PASSWORD
  secret SECRET 64
  envset ADMIN_PW "$ADMIN_PW"
  # image chạy bằng user node (1000): thư mục tải lên phải ghi được, không thì /server/health báo lỗi storage
  install -d -o 1000 -g 1000 "$APP_DIR/uploads" "$APP_DIR/extensions"
  cat > "$APP_DIR/compose.yaml" <<EOF
services:
  db:
    image: $DB_IMAGE
    restart: unless-stopped
    environment:
      POSTGRES_USER: directus
      POSTGRES_PASSWORD: \${DB_PASSWORD}
      POSTGRES_DB: directus
    volumes:
      - ./db:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U directus -d directus"]
      interval: 5s
      retries: 60
  directus:
    image: $IMAGE
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
    environment:
      SECRET: \${SECRET}
      DB_CLIENT: pg
      DB_HOST: db
      DB_PORT: "5432"
      DB_DATABASE: directus
      DB_USER: directus
      DB_PASSWORD: \${DB_PASSWORD}
      # chỉ dùng khi bootstrap CSDL trống lần đầu; về sau đổi mật khẩu trong giao diện không bị ghi đè
      ADMIN_EMAIL: $ADMIN_USER
      ADMIN_PASSWORD: \${ADMIN_PW}
      PUBLIC_URL: ${TINO_URL%/}
    volumes:
      - ./uploads:/directus/uploads
      - ./extensions:/directus/extensions
    ports:
      - "127.0.0.1:$APP_PORT:8055"
EOF
}

# Quản trị do "directus bootstrap" (entrypoint) tạo từ ADMIN_EMAIL/ADMIN_PASSWORD; ở đây chỉ đăng nhập thử.
app_setup() {
  jq -n --arg e "$ADMIN_USER" --arg p "$ADMIN_PW" '{email: $e, password: $p}' |
    api POST /auth/login -H 'Content-Type: application/json' --data-binary @- | jq -e '.data.access_token' >/dev/null
}
