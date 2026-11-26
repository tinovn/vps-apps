APP_VERSION=28.4.0
IMAGE='gitea/gitea:28.4.0@sha256:aa90e8f00b755b0d665214ab9c14447ea44d3190dbe6b6d0cb46cd9c4f55d309'
ADMIN_USER='gitadmin'  # Gitea giữ chỗ tên "admin"
APP_NOTE='Git qua HTTPS; SSH của Gitea tắt (cổng 22 là SSH của VPS). Đăng ký tự do đang tắt, quản trị tạo thêm người dùng.'

app_files() {
  secret SECRET_KEY 64
  secret INTERNAL_TOKEN 64
  cat > "$APP_DIR/compose.yaml" <<EOF
services:
  gitea:
    image: $IMAGE
    container_name: gitea
    restart: unless-stopped
    environment:
      USER_UID: "1000"
      USER_GID: "1000"
      GITEA__database__DB_TYPE: sqlite3
      GITEA__server__ROOT_URL: $TINO_URL
      GITEA__server__DOMAIN: $TINO_HOST
      GITEA__server__HTTP_PORT: "3000"
      GITEA__server__DISABLE_SSH: "true"
      GITEA__server__START_SSH_SERVER: "false"
      GITEA__security__INSTALL_LOCK: "true"
      GITEA__security__SECRET_KEY: \${SECRET_KEY}
      GITEA__security__INTERNAL_TOKEN: \${INTERNAL_TOKEN}
      GITEA__service__DISABLE_REGISTRATION: "true"
    volumes:
      - ./data:/data
    ports:
      - "127.0.0.1:$APP_PORT:3000"
EOF
}

app_setup() {
  if ! docker exec -u git gitea gitea admin user list --admin | awk '{print $2}' | grep -qxF "$ADMIN_USER"; then
    docker exec -u git gitea gitea admin user create --username "$ADMIN_USER" --password "$ADMIN_PW" \
      --email "admin@$TINO_HOST" --admin --must-change-password=false >/dev/null
  fi
  # đăng nhập thử bằng Basic auth (mật khẩu đi qua stdin của curl, không nằm trên dòng lệnh)
  api GET /api/v1/user -K - <<<"user = \"$ADMIN_USER:$ADMIN_PW\"" | jq -e '.is_admin == true' >/dev/null
}
