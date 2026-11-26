APP_VERSION=3.5.0
IMAGE='ghcr.io/paperless-ngx/paperless-ngx:3.5.0@sha256:8c1e2c4e0abb50576c7a09f062ed581e2d955e298a302e1e196a35338639005e'
DB_IMAGE='postgres:18.7-alpine@sha256:b6972e1115a4ff8eba5d7f7d19184926d1e16d7d1136ae1e1a7ebf286da0f015'
BROKER_IMAGE='valkey/valkey:9.1.3-alpine@sha256:bf09d58e96d6b4524a15396b65b242bbe18beebbcc15a04d8ee75ddac62fae0b'
WAIT_SECS=600  # lần đầu chạy migration và tải dữ liệu OCR
APP_NOTE='Tải tài liệu lên qua giao diện web hoặc chép vào /opt/paperless-ngx/consume trên VPS; OCR nhận tiếng Việt và tiếng Anh.'

app_files() {
  secret DB_PASSWORD
  secret SECRET_KEY 64
  envset ADMIN_PW "$ADMIN_PW"
  # Có PAPERLESS_URL thì ALLOWED_HOSTS chỉ còn host đó + localhost: thêm 127.0.0.1 cho healthcheck của HostBill (Django trả 400 nếu thiếu)
  cat > "$APP_DIR/compose.yaml" <<EOF2
services:
  broker:
    image: $BROKER_IMAGE
    restart: unless-stopped
    volumes:
      - ./redis:/data
  db:
    image: $DB_IMAGE
    restart: unless-stopped
    environment:
      POSTGRES_DB: paperless
      POSTGRES_USER: paperless
      POSTGRES_PASSWORD: \${DB_PASSWORD}
    volumes:
      - ./db:/var/lib/postgresql
    healthcheck:
      test: ["CMD", "pg_isready", "-h", "127.0.0.1", "-U", "paperless", "-d", "paperless"]
      interval: 5s
      retries: 60
  webserver:
    image: $IMAGE
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
      broker:
        condition: service_started
    environment:
      PAPERLESS_REDIS: redis://broker:6379
      PAPERLESS_DBENGINE: postgresql
      PAPERLESS_DBHOST: db
      PAPERLESS_DBNAME: paperless
      PAPERLESS_DBUSER: paperless
      PAPERLESS_DBPASS: \${DB_PASSWORD}
      PAPERLESS_SECRET_KEY: \${SECRET_KEY}
      PAPERLESS_URL: ${TINO_URL%/}
      PAPERLESS_ALLOWED_HOSTS: "$TINO_HOST,127.0.0.1,localhost"
      PAPERLESS_PROXY_SSL_HEADER: '["HTTP_X_FORWARDED_PROTO", "https"]'
      PAPERLESS_TIME_ZONE: Asia/Ho_Chi_Minh
      # gói tesseract-ocr-vie được entrypoint cài bằng apt khi tạo container (init-tesseract-langs)
      PAPERLESS_OCR_LANGUAGES: vie
      PAPERLESS_OCR_LANGUAGE: vie+eng
      PAPERLESS_ADMIN_USER: $ADMIN_USER
      PAPERLESS_ADMIN_MAIL: admin@$TINO_HOST
      PAPERLESS_ADMIN_PASSWORD: \${ADMIN_PW}
    volumes:
      - ./data:/usr/src/paperless/data
      - ./media:/usr/src/paperless/media
      - ./export:/usr/src/paperless/export
      - ./consume:/usr/src/paperless/consume
    ports:
      - "127.0.0.1:$APP_PORT:8000"
EOF2
}

# Quản trị do s6 init-superuser tạo lúc khởi động (manage_superuser: bỏ qua khi đã có superuser). Đăng nhập thử lấy token API.
app_setup() {
  jq -n --arg u "$ADMIN_USER" --arg p "$ADMIN_PW" '{username: $u, password: $p}' |
    api POST /api/token/ -H 'Content-Type: application/json' -d @- | jq -e '.token' >/dev/null ||
    refuse 'Paperless-ngx trên VPS đã có tài khoản quản trị từ trước với mật khẩu khác.'
}
