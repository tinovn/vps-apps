APP_VERSION=2.38.1
IMAGE='binwiederhier/ntfy:v2.38.1@sha256:038da2be5e668fee6d36a62884eea48975e1b71c29a56964e5298c1b9165a573'
APP_NOTE='Mọi chủ đề (topic) đều cần đăng nhập. Tạo người dùng và token gửi tin bằng lệnh: docker exec -it ntfy ntfy user add <tên> / ntfy token add <tên>.'

app_files() {
  install -d -m 755 "$APP_DIR/data"
  cat > "$APP_DIR/server.yml" <<EOF
base-url: "${TINO_URL%/}"
listen-http: ":80"
behind-proxy: true
cache-file: /var/lib/ntfy/cache.db
attachment-cache-dir: /var/lib/ntfy/attachments
auth-file: /var/lib/ntfy/user.db
auth-default-access: deny-all
enable-login: true
require-login: true
enable-signup: false
EOF
  cat > "$APP_DIR/compose.yaml" <<EOF
services:
  ntfy:
    image: $IMAGE
    container_name: ntfy
    restart: unless-stopped
    command: serve
    volumes:
      - ./server.yml:/etc/ntfy/server.yml:ro
      - ./data:/var/lib/ntfy
    ports:
      - "127.0.0.1:$APP_PORT:80"
EOF
}

app_setup() {
  # mật khẩu qua biến NTFY_PASSWORD (docker exec -e chỉ chép tên biến, không nằm trên dòng lệnh)
  NTFY_PASSWORD=$ADMIN_PW docker exec -e NTFY_PASSWORD ntfy ntfy user add --role=admin --ignore-exists "$ADMIN_USER" >/dev/null
  api GET /v1/account -K - <<<"user = \"$ADMIN_USER:$ADMIN_PW\"" |
    jq -e --arg u "$ADMIN_USER" '.username == $u and .role == "admin"' >/dev/null
}
