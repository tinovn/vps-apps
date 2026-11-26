APP_VERSION=26.09.3
# BookStack không phát hành image chính thức; dùng image của linuxserver.io (được tài liệu BookStack giới thiệu)
IMAGE='ghcr.io/linuxserver/bookstack:v26.09.3-ls298@sha256:7a80c1685f59c264f791b14e836380b982f058438447031ec2136d867eb72a79'
DB_IMAGE='mariadb:11.8.9@sha256:d36f18d65a0459510b8b0f643b226a6d299e3206486e2b64ff20754a6d291707'
ADMIN_USER="admin@$TINO_HOST"  # BookStack đăng nhập bằng email
APP_NOTE='Đăng nhập bằng email quản trị; thêm thành viên ở Settings → Users.'

app_files() {
  secret DB_PASSWORD
  secret APP_KEY 32  # khoá AES-256 của Laravel: chuỗi 32 ký tự
  cat > "$APP_DIR/compose.yaml" <<EOF
services:
  db:
    image: $DB_IMAGE
    restart: unless-stopped
    environment:
      MARIADB_DATABASE: bookstack
      MARIADB_USER: bookstack
      MARIADB_PASSWORD: \${DB_PASSWORD}
      MARIADB_RANDOM_ROOT_PASSWORD: "1"
    volumes:
      - ./db:/var/lib/mysql
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
      interval: 5s
      retries: 60
  bookstack:
    image: $IMAGE
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
    environment:
      PUID: "1000"
      PGID: "1000"
      TZ: Asia/Ho_Chi_Minh
      APP_URL: ${TINO_URL%/}
      APP_KEY: \${APP_KEY}
      DB_HOST: db
      DB_PORT: "3306"
      DB_USERNAME: bookstack
      DB_PASSWORD: \${DB_PASSWORD}
      DB_DATABASE: bookstack
    volumes:
      - ./config:/config
    ports:
      - "127.0.0.1:$APP_PORT:80"
EOF
}

# Đăng nhập thử qua form web (API của BookStack chỉ nhận token): đúng → chuyển về trang chủ, sai → về /login.
# Cookie phiên có cờ Secure (APP_URL https); curl vẫn gửi cho 127.0.0.1.
bs_login() {
  local jar tok loc
  jar=$(mktemp)
  tok=$(curl -sS -c "$jar" "http://127.0.0.1:$APP_PORT/login" | sed -n 's/.*<meta name="token" content="\([^"]*\)".*/\1/p')
  loc=$(curl -sS -o /dev/null -b "$jar" -w '%{redirect_url}' --data-urlencode "_token=$tok" --data-urlencode "email=$ADMIN_USER" \
    -K - "http://127.0.0.1:$APP_PORT/login" <<<"data-urlencode = \"password=$ADMIN_PW\"")
  rm -f "$jar"
  [ -n "$loc" ] && [ "${loc%/login}" = "$loc" ]
}

# Migration tạo sẵn admin@admin.com / password. --initial đổi chính tài khoản đó sang email, mật khẩu của khách
# (CreateAdminCommand); đã có quản trị khác thì lệnh trả 2 và không đổi gì. Chạy trước khi mở HTTPS.
app_setup() {
  local rc=0
  # mật khẩu qua stdin, không nằm trên dòng lệnh docker exec (artisan chỉ nhận --password, không đọc stdin khi không có tty)
  compose exec -T bookstack sh -c \
    'read -r p; exec php /app/www/artisan bookstack:create-admin --initial --no-interaction --email="$1" --name=Admin --password="$p"' \
    _ "$ADMIN_USER" <<<"$ADMIN_PW" || rc=$?
  case $rc in
    0) bs_login || die 'Đã đặt tài khoản quản trị BookStack nhưng đăng nhập thử không được.' ;;
    2) bs_login || refuse 'BookStack trên VPS đã có tài khoản quản trị từ trước với mật khẩu khác.' ;;
    *) exit 1 ;;
  esac
}
