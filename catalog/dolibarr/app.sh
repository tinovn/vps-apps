APP_VERSION=24.0.2
IMAGE='dolibarr/dolibarr:24.0.2@sha256:0fab863277ca8f88759ecf6857325a55ee43a0457c94c54459db036bf19d3cae'
DB_IMAGE='mariadb:11.8.9@sha256:d36f18d65a0459510b8b0f643b226a6d299e3206486e2b64ff20754a6d291707'

app_files() {
  secret DB_PASSWORD
  secret INSTANCE_ID 32
  envset ADMIN_PW "$ADMIN_PW"
  cat > "$APP_DIR/compose.yaml" <<EOF
services:
  db:
    image: $DB_IMAGE
    restart: unless-stopped
    # như docker-compose.yml của dolibarr-docker: khớp db_character_set / db_collation trong conf.php
    command: --character-set-server=utf8mb4 --collation-server=utf8mb4_unicode_ci
    environment:
      MARIADB_DATABASE: dolibarr
      MARIADB_USER: dolibarr
      MARIADB_PASSWORD: \${DB_PASSWORD}
      MARIADB_RANDOM_ROOT_PASSWORD: "1"
    volumes:
      - ./db:/var/lib/mysql
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
      interval: 5s
      retries: 60
  web:
    image: $IMAGE
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
    environment:
      DOLI_DB_HOST: db
      DOLI_DB_NAME: dolibarr
      DOLI_DB_USER: dolibarr
      DOLI_DB_PASSWORD: \${DB_PASSWORD}
      DOLI_URL_ROOT: ${TINO_URL%/}
      DOLI_ADMIN_LOGIN: $ADMIN_USER
      DOLI_ADMIN_PASSWORD: \${ADMIN_PW}
      DOLI_INSTANCE_UNIQUE_ID: \${INSTANCE_ID}
      PHP_INI_DATE_TIMEZONE: Asia/Ho_Chi_Minh
    volumes:
      - ./documents:/var/www/documents
      # volume có tên: giữ quyền www-data của image cho module cài thêm
      - custom:/var/www/html/custom
    ports:
      - "127.0.0.1:$APP_PORT:80"
volumes:
  custom:
EOF
}

# docker-run.sh của image (DOLI_INSTALL_AUTO=1 mặc định) tạo bảng + quản trị từ DOLI_ADMIN_* khi CSDL trống rồi khoá
# install.lock; Apache chỉ bật sau bước đó. Đăng nhập thử bằng chính hàm kiểm mật khẩu của Dolibarr, PHP CLI trong container.
app_setup() {
  compose exec -T web php <<'PHP' || die 'Không đăng nhập thử được tài khoản quản trị Dolibarr.'
<?php
require '/var/www/html/master.inc.php';
require_once DOL_DOCUMENT_ROOT.'/core/lib/security2.lib.php';
$u = getenv('DOLI_ADMIN_LOGIN');
exit(checkLoginPassEntity($u, getenv('DOLI_ADMIN_PASSWORD'), 1, array('dolibarr')) === $u ? 0 : 1);
PHP
}
