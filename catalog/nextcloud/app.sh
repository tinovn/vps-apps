APP_VERSION=35.0.3
IMAGE='nextcloud:35.0.3-apache@sha256:8a7a65b8bae82a79568fec2ed9cf3e374a1944eda2a22ebe130d79463336fee3'
DB_IMAGE='postgres:18.7-alpine@sha256:b6972e1115a4ff8eba5d7f7d19184926d1e16d7d1136ae1e1a7ebf286da0f015'
REDIS_IMAGE='redis:8.10.3-alpine@sha256:7958cfbb9d152f87dadfbc89f1b0b15938f0b81ff8982feb327476f4911935c3'
WAIT_SECS=900  # lần đầu entrypoint chép mã và chạy occ maintenance:install rồi Apache mới nghe cổng
APP_NOTE='Ứng dụng Nextcloud trên điện thoại / máy tính đăng nhập bằng địa chỉ trên; tác vụ nền chạy bằng cron mỗi 5 phút.'

app_files() {
  secret DB_PASSWORD
  envset ADMIN_PW "$ADMIN_PW"
  # Entrypoint của image tự cài khi thư mục trống và có đủ NEXTCLOUD_ADMIN_* + POSTGRES_*; trusted_domains[0] = localhost.
  cat > "$APP_DIR/compose.yaml" <<EOF
services:
  db:
    image: $DB_IMAGE
    restart: unless-stopped
    environment:
      POSTGRES_DB: nextcloud
      POSTGRES_USER: nextcloud
      POSTGRES_PASSWORD: \${DB_PASSWORD}
    volumes:
      - ./db:/var/lib/postgresql
    healthcheck:
      test: ["CMD", "pg_isready", "-h", "127.0.0.1", "-U", "nextcloud", "-d", "nextcloud"]
      interval: 5s
      retries: 60
  redis:
    image: $REDIS_IMAGE
    restart: unless-stopped
  app:
    image: $IMAGE
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_started
    environment:
      POSTGRES_HOST: db
      POSTGRES_DB: nextcloud
      POSTGRES_USER: nextcloud
      POSTGRES_PASSWORD: \${DB_PASSWORD}
      REDIS_HOST: redis
      NEXTCLOUD_ADMIN_USER: $ADMIN_USER
      NEXTCLOUD_ADMIN_PASSWORD: \${ADMIN_PW}
      NEXTCLOUD_TRUSTED_DOMAINS: "$TINO_HOST 127.0.0.1"
      OVERWRITEPROTOCOL: https
      OVERWRITECLIURL: ${TINO_URL%/}
      # Caddy đi vào qua cổng docker (IP gateway của mạng bridge): tin X-Forwarded-For từ dải riêng
      TRUSTED_PROXIES: "172.16.0.0/12 192.168.0.0/16 10.0.0.0/8"
    volumes:
      - ./html:/var/www/html
    ports:
      - "127.0.0.1:$APP_PORT:80"
  cron:
    image: $IMAGE
    restart: unless-stopped
    entrypoint: /cron.sh
    depends_on:
      - app
    volumes:
      - ./html:/var/www/html
EOF
}

occ() { compose exec -T -u www-data app php occ "$@"; }

app_setup() {
  occ status --output=json | jq -e '.installed == true' >/dev/null || die 'Nextcloud chưa cài xong, xem: docker compose logs app.'
  occ background:cron >/dev/null
  # đăng nhập thử qua OCS API bằng Basic auth (mật khẩu qua stdin của curl)
  api GET '/ocs/v2.php/cloud/user?format=json' -H 'OCS-APIRequest: true' -K - <<<"user = \"$ADMIN_USER:$ADMIN_PW\"" |
    jq -e --arg u "$ADMIN_USER" '.ocs.data.id == $u' >/dev/null
}
