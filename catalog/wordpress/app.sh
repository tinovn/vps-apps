APP_VERSION=7.1.4
WP_IMAGE='wordpress:7.1.4-php8.4-apache@sha256:4bf2c44f19a5eba28de4e5cbe50e1c5dc55ae3f8b894f681f4d7676a7e2512e5'
CLI_IMAGE='wordpress:cli-2.12.0-php8.4@sha256:858dc76209146b8b5544fbdfde6fbb364fd7545c0114aebbccb52144adb50b5c'
DB_IMAGE='mariadb:11.8.9@sha256:d36f18d65a0459510b8b0f643b226a6d299e3206486e2b64ff20754a6d291707'

app_files() {
  secret DB_PASSWORD
  cat > "$APP_DIR/compose.yaml" <<EOF
x-wp-env: &wp-env
  WORDPRESS_DB_HOST: db
  WORDPRESS_DB_NAME: wordpress
  WORDPRESS_DB_USER: wordpress
  WORDPRESS_DB_PASSWORD: \${DB_PASSWORD}
services:
  db:
    image: $DB_IMAGE
    restart: unless-stopped
    environment:
      MARIADB_DATABASE: wordpress
      MARIADB_USER: wordpress
      MARIADB_PASSWORD: \${DB_PASSWORD}
      MARIADB_RANDOM_ROOT_PASSWORD: "1"
    volumes:
      - ./db:/var/lib/mysql
    healthcheck:
      test: ["CMD", "healthcheck.sh", "--connect", "--innodb_initialized"]
      interval: 5s
      retries: 60
  wordpress:
    image: $WP_IMAGE
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
    environment: *wp-env
    volumes:
      - ./html:/var/www/html
    ports:
      - "127.0.0.1:$APP_PORT:80"
  # wp-cli: chạy bằng uid 33 (www-data của image apache), image cli là alpine (www-data = 82)
  cli:
    image: $CLI_IMAGE
    profiles: [cli]
    user: "33:33"
    environment: *wp-env
    volumes:
      - ./html:/var/www/html
EOF
}

wp() { compose run --rm -T cli wp "$@"; }

app_setup() {
  local url=${TINO_URL%/}
  if ! wp core is-installed >/dev/null 2>&1; then
    wp core install --url="$url" --title='WordPress' --admin_user="$ADMIN_USER" --admin_email="admin@$TINO_HOST" \
      --skip-email --prompt=admin_password <<<"$ADMIN_PW"
  fi
  wp option update home "$url" >/dev/null
  wp option update siteurl "$url" >/dev/null
  if declare -F wp_extra >/dev/null; then wp_extra; fi  # app dùng lại khuôn này (#@use wordpress), vd. woocommerce
  wp user get "$ADMIN_USER" --field=roles | grep -q administrator
}
