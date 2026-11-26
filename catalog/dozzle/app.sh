APP_VERSION=11.4.3
IMAGE='amir20/dozzle:v11.4.3@sha256:244f218c876d6ed766277e71a537f34bfb2c01829e1927737e3673a8327deeb8'
APP_NOTE='Chỉ xem log container (bật/tắt container và shell đang tắt); thêm người dùng trong /opt/dozzle/data/users.yml.'

app_files() {
  # Đăng nhập "simple": users.yml (băm bcrypt bằng "dozzle generate", mật khẩu qua stdin). Có rồi thì giữ nguyên.
  install -d -m 700 "$APP_DIR/data"
  if [ ! -s "$APP_DIR/data/users.yml" ]; then
    (
      umask 077
      docker run --rm -i -e DOZZLE_NO_ANALYTICS=true "$IMAGE" generate "$ADMIN_USER" --name Admin \
        <<<"$ADMIN_PW" > "$APP_DIR/data/users.yml.tmp"
      grep -q 'password: \$2' "$APP_DIR/data/users.yml.tmp"
      mv "$APP_DIR/data/users.yml.tmp" "$APP_DIR/data/users.yml"
    )
  fi
  cat > "$APP_DIR/compose.yaml" <<EOF
services:
  dozzle:
    image: $IMAGE
    container_name: dozzle
    restart: unless-stopped
    environment:
      DOZZLE_AUTH_PROVIDER: simple
      DOZZLE_NO_ANALYTICS: "true"
    volumes:
      - ./data:/data
      - /var/run/docker.sock:/var/run/docker.sock:ro
    ports:
      - "127.0.0.1:$APP_PORT:8080"
EOF
}

app_setup() {
  # đăng nhập thử: POST /api/token (form username/password) trả 200; mật khẩu qua stdin của curl
  api POST /api/token --data-urlencode "username=$ADMIN_USER" -K - <<<"data-urlencode = \"password=$ADMIN_PW\"" >/dev/null
}
