APP_VERSION=6.77.0
IMAGE='ghost:6.77.0@sha256:2e3ca97643ea2a8cde6d0c97fae15ff39bfb60714f5abaab3f65263a2ed7c2a7'
DB_IMAGE='mysql:8.0.46@sha256:7dcddc01f13bab2f15cde676d44d01f61fc9f99fe7785e86196dfc07d358ae2b'
ADMIN_USER="admin@$TINO_HOST"  # Ghost đăng nhập bằng email
WAIT_SECS=600  # lần đầu: MySQL khởi tạo rồi Ghost chạy migration
APP_NOTE='Trang quản trị ở /ghost/. VPS chưa có máy chủ gửi mail: muốn mời thành viên, gửi bản tin, lấy lại mật khẩu thì cấu hình mail (biến mail__… của Ghost).'

app_files() {
  secret DB_PASSWORD
  secret DB_ROOT_PASSWORD
  cat > "$APP_DIR/compose.yaml" <<EOF
services:
  db:
    image: $DB_IMAGE
    restart: unless-stopped
    environment:
      MYSQL_ROOT_PASSWORD: \${DB_ROOT_PASSWORD}
      MYSQL_DATABASE: ghost
      MYSQL_USER: ghost
      MYSQL_PASSWORD: \${DB_PASSWORD}
    volumes:
      - ./mysql:/var/lib/mysql
    healthcheck:
      # ping trả 0 khi máy chủ đã nghe TCP (kể cả bị từ chối đăng nhập); lúc khởi tạo MySQL chưa nghe TCP
      test: ["CMD", "mysqladmin", "ping", "-h", "127.0.0.1", "--silent"]
      interval: 5s
      retries: 60
  ghost:
    image: $IMAGE
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
    environment:
      NODE_ENV: production
      url: $TINO_URL
      database__client: mysql
      database__connection__host: db
      database__connection__user: ghost
      database__connection__password: \${DB_PASSWORD}
      database__connection__database: ghost
      # Mặc định Ghost gửi mã xác minh qua email khi đăng nhập từ thiết bị mới; chưa có mail thì khách không vào được
      security__staffDeviceVerification: "false"
    volumes:
      - ./content:/var/lib/ghost/content
    ports:
      - "127.0.0.1:$APP_PORT:2368"
EOF
}

# Chủ site tạo qua API "setup" (như trang /ghost/#/setup, chỉ được khi chưa có chủ site), rồi đăng nhập thử bằng session.
# Session kiểm Origin = url của site; X-Forwarded-Proto như Caddy gửi.
app_setup() {
  local h=(-H 'Content-Type: application/json' -H 'X-Forwarded-Proto: https' -H "Origin: ${TINO_URL%/}")
  if api GET /ghost/api/admin/authentication/setup/ | jq -e '.setup[0].status == false' >/dev/null; then
    jq -n --arg e "$ADMIN_USER" --arg p "$ADMIN_PW" '{setup: [{name: "Admin", email: $e, password: $p, blogTitle: "Ghost"}]}' |
      api POST /ghost/api/admin/authentication/setup/ "${h[@]}" --data-binary @- >/dev/null
  fi
  jq -n --arg u "$ADMIN_USER" --arg p "$ADMIN_PW" '{username: $u, password: $p}' |
    api POST /ghost/api/admin/session/ "${h[@]}" --data-binary @- >/dev/null
}
