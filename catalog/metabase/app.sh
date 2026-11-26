APP_VERSION=0.65.4
IMAGE='metabase/metabase:v0.65.4@sha256:a562492ba594acd71a2976a08dfcb4a67af7ad56a614048c7a10af18ec560e3c'
DB_IMAGE='postgres:17.12-alpine@sha256:a77aa70e641402a21411b92b721c58d10f23b50ae5fdd2333efd22d166e1e5f7'
ADMIN_USER="admin@$TINO_HOST"  # Metabase đăng nhập bằng email
WAIT_SECS=900                  # Java + tạo bảng lần đầu: vài phút trên VPS nhỏ
APP_NOTE='Thêm nguồn dữ liệu trong Admin → Databases. Lần đầu mở có thể chậm vài giây (Java khởi động).'

app_files() {
  secret DB_PASSWORD
  secret MB_ENCRYPTION_SECRET_KEY 32
  cat > "$APP_DIR/compose.yaml" <<EOF
services:
  db:
    image: $DB_IMAGE
    restart: unless-stopped
    environment:
      POSTGRES_USER: metabase
      POSTGRES_PASSWORD: \${DB_PASSWORD}
      POSTGRES_DB: metabase
    volumes:
      - ./db:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U metabase -d metabase"]
      interval: 5s
      retries: 60
  metabase:
    image: $IMAGE
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
    environment:
      MB_DB_TYPE: postgres
      MB_DB_HOST: db
      MB_DB_PORT: "5432"
      MB_DB_DBNAME: metabase
      MB_DB_USER: metabase
      MB_DB_PASS: \${DB_PASSWORD}
      MB_ENCRYPTION_SECRET_KEY: \${MB_ENCRYPTION_SECRET_KEY}
      MB_SITE_URL: ${TINO_URL%/}
      MB_ANON_TRACKING_ENABLED: "false"
      # JVM mặc định chỉ lấy 25% RAM cho heap
      JAVA_OPTS: -XX:MaxRAMPercentage=50
    ports:
      - "127.0.0.1:$APP_PORT:3000"
EOF
}

# Như trang cài đặt lần đầu: lấy setup-token ở /api/session/properties rồi POST /api/setup (chỉ khi chưa có người dùng).
app_setup() {
  local props
  props=$(api GET /api/session/properties)
  if jq -e '."has-user-setup" != true' <<<"$props" >/dev/null; then
    jq -n --arg t "$(jq -r '."setup-token"' <<<"$props")" --arg e "$ADMIN_USER" --arg p "$ADMIN_PW" \
      '{token: $t, user: {email: $e, password: $p, first_name: "Admin"}, prefs: {site_name: "Metabase"}}' |
      api POST /api/setup -H 'Content-Type: application/json' --data-binary @- >/dev/null
  fi
  jq -n --arg u "$ADMIN_USER" --arg p "$ADMIN_PW" '{username: $u, password: $p}' |
    api POST /api/session -H 'Content-Type: application/json' --data-binary @- | jq -e '.id' >/dev/null
}
