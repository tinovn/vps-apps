APP_VERSION=9.2.1
IMAGE='prestashop/prestashop:9.2.1-apache@sha256:fb3758bb6d7cb14ff1163029c094af09607ae02727f70dac7eecb4fe0d6f0b01'
DB_IMAGE='mariadb:11.8.9@sha256:d36f18d65a0459510b8b0f643b226a6d299e3206486e2b64ff20754a6d291707'
ADMIN_USER="admin@$TINO_HOST"  # quản trị PrestaShop đăng nhập bằng email
WAIT_SECS=900  # image chạy trình cài (index_cli.php) xong mới bật Apache

app_files() {
  secret DB_PASSWORD
  secret ADMIN_DIR 10  # thư mục quản trị đổi tên ngẫu nhiên thay cho /admin
  envset ADMIN_PW "$ADMIN_PW"
  APP_NOTE="Trang quản trị: ${TINO_URL}admin$(envget ADMIN_DIR)/ (đăng nhập bằng email). Giữ kín đường dẫn này."
  cat > "$APP_DIR/compose.yaml" <<EOF
services:
  db:
    image: $DB_IMAGE
    restart: unless-stopped
    environment:
      MARIADB_DATABASE: prestashop
      MARIADB_USER: prestashop
      MARIADB_PASSWORD: \${DB_PASSWORD}
      MARIADB_RANDOM_ROOT_PASSWORD: "1"
    volumes:
      - ./db:/var/lib/mysql
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
      interval: 5s
      retries: 60
  prestashop:
    image: $IMAGE
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
    environment:
      DB_SERVER: db
      DB_NAME: prestashop
      DB_USER: prestashop
      DB_PASSWD: \${DB_PASSWORD}
      PS_INSTALL_AUTO: "1"
      PS_DOMAIN: $TINO_HOST
      PS_ENABLE_SSL: "1"
      PS_FOLDER_ADMIN: admin\${ADMIN_DIR}
      ADMIN_MAIL: $ADMIN_USER
      ADMIN_PASSWD: \${ADMIN_PW}
      # trang quản trị (Symfony) chỉ tin X-Forwarded-Proto của Caddy khi đến từ mạng riêng (cổng docker)
      PS_TRUSTED_PROXIES: 127.0.0.1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16
    volumes:
      # volume có tên: docker chép mã PrestaShop của image (chủ www-data) vào lần đầu
      - html:/var/www/html
    ports:
      - "127.0.0.1:$APP_PORT:80"
volumes:
  html:
EOF
}

# Quản trị do docker_run.sh của image tạo (index_cli.php với ADMIN_MAIL/ADMIN_PASSWD), chỉ khi chưa cài; cài lỗi thì image
# vẫn bật Apache. Đăng nhập thử: lấy nhân viên trong CSDL, so mật khẩu bằng password_verify như PrestaShop (bcrypt).
app_setup() {
  compose exec -T prestashop php -r '
    $db = new PDO("mysql:host=db;dbname=prestashop", getenv("DB_USER"), getenv("DB_PASSWD"));
    $s = $db->prepare("SELECT passwd FROM ps_employee WHERE email = ? AND active = 1");
    $s->execute([getenv("ADMIN_MAIL")]);
    exit(password_verify(getenv("ADMIN_PASSWD"), (string) $s->fetchColumn()) ? 0 : 1);' ||
    die 'PrestaShop chưa cài xong hoặc không đăng nhập thử được (xem: docker compose logs prestashop).'
}
