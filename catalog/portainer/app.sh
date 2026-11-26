APP_VERSION=2.45.3
IMAGE='portainer/portainer-ce:2.45.3@sha256:3609c307943bca8e5c492f69ddd6965df177208b50678a4cff28391c8dd4e96e'
APP_NOTE='Portainer có toàn quyền Docker trên VPS (tương đương root): giữ kín mật khẩu, chỉ cấp tài khoản cho người tin cậy. Tên đăng nhập luôn là admin.'

app_files() {
  # Portainer đọc tệp này lần chạy đầu để tạo user admin; đã có admin thì bỏ qua (chạy lại không đổi mật khẩu)
  ( umask 077; printf '%s' "$ADMIN_PW" > "$APP_DIR/admin_password" )
  cat > "$APP_DIR/compose.yaml" <<EOF
services:
  portainer:
    image: $IMAGE
    restart: unless-stopped
    # chỉ HTTP 9000 ra 127.0.0.1 (Caddy lo HTTPS); 9443 và 8000 (edge tunnel) không publish
    command: --http-enabled --admin-password-file /run/secrets/tino_admin_password -H unix:///var/run/docker.sock
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./data:/data
      - ./admin_password:/run/secrets/tino_admin_password:ro
    ports:
      - "127.0.0.1:$APP_PORT:9000"
EOF
}

app_setup() {
  jq -n --arg u "$ADMIN_USER" --arg p "$ADMIN_PW" '{username: $u, password: $p}' |
    api POST /api/auth -H 'Content-Type: application/json' --data-binary @- | jq -e '.jwt' >/dev/null
}
