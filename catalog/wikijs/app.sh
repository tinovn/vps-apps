APP_VERSION=3.4.0
IMAGE='ghcr.io/requarks/wiki:3.4.0@sha256:9424867464d9d899f975bbadb8ff1f794341eadd720b5fb5c22f0988c62e29bf'
DB_IMAGE='postgres:18.7-alpine@sha256:b6972e1115a4ff8eba5d7f7d19184926d1e16d7d1136ae1e1a7ebf286da0f015'
ADMIN_USER="admin@$TINO_HOST"  # Wiki.js đăng nhập bằng email
WAIT_SECS=600  # lần đầu chạy migration và tạo dữ liệu mẫu
APP_NOTE='Đăng nhập bằng email quản trị; vào Administration → Users để mời thành viên, Administration → Sites để đổi tên wiki.'

app_files() {
  secret DB_PASSWORD
  envset ADMIN_PW "$ADMIN_PW"
  # ADMIN_EMAIL / ADMIN_PASS chỉ được đọc ở lần khởi động đầu với CSDL trống (backend/models/users.ts init)
  cat > "$APP_DIR/compose.yaml" <<EOF
services:
  db:
    image: $DB_IMAGE
    restart: unless-stopped
    environment:
      POSTGRES_DB: wiki
      POSTGRES_USER: wiki
      POSTGRES_PASSWORD: \${DB_PASSWORD}
    volumes:
      - ./db:/var/lib/postgresql
    healthcheck:
      test: ["CMD", "pg_isready", "-h", "127.0.0.1", "-U", "wiki", "-d", "wiki"]
      interval: 5s
      retries: 60
  wiki:
    image: $IMAGE
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
    environment:
      DB_HOST: db
      DB_PORT: "5432"
      DB_USER: wiki
      DB_PASS: \${DB_PASSWORD}
      DB_NAME: wiki
      DB_SSL: "false"
      ADMIN_EMAIL: $ADMIN_USER
      ADMIN_PASS: \${ADMIN_PW}
    volumes:
      - data:/wiki/data
    ports:
      - "127.0.0.1:$APP_PORT:3000"
volumes:
  data:
EOF
}

# Đăng nhập thử qua REST (backend/api/authentication.ts), rồi bật trustProxy để giới hạn đăng nhập sai tính theo IP
# khách (X-Forwarded-For của Caddy) thay vì IP gateway docker chung cho mọi người.
app_setup() {
  local sid stid jar
  sid=$(api GET /_api/bootstrap | jq -er '.site.id')
  stid=$(api GET "/_api/sites/$sid/auth/strategies" | jq -er 'map(select(.activeStrategy.strategy.key == "local"))[0].id')
  jar=$(mktemp)
  jq -n --arg s "$stid" --arg u "$ADMIN_USER" --arg p "$ADMIN_PW" '{strategyId: $s, username: $u, password: $p}' |
    api PUT "/_api/sites/$sid/auth/login" -c "$jar" -H 'Content-Type: application/json' -d @- |
    jq -e '.ok == true and .nextAction == "redirect"' >/dev/null
  # bước gia cố, không chặn cài đặt: lỗi thì nhắc khách tự bật
  api PUT /_api/system/security -b "$jar" -H 'Content-Type: application/json' -d '{"trustProxy": true}' >/dev/null ||
    note 'Hãy bật "Trust X-Forwarded-* Proxy Headers" ở Administration → Security để Wiki.js thấy đúng IP người dùng.'
  rm -f "$jar"
}
