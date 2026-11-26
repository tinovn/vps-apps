APP_VERSION=12.1.0
IMAGE='mattermost/mattermost-team-edition:12.1.0@sha256:35927b9c535a9eb74f0e45385d3fe5d8308b16e0464031f157a834da8af3ee73'
DB_IMAGE='postgres:18.7-alpine@sha256:b6972e1115a4ff8eba5d7f7d19184926d1e16d7d1136ae1e1a7ebf286da0f015'
APP_NOTE='Đăng ký tự do đang tắt: tạo nhóm (team) đầu tiên rồi mời thành viên bằng liên kết mời. Ứng dụng điện thoại / máy tính nhập địa chỉ trên.'

app_files() {
  secret DB_PASSWORD
  # image chạy bằng uid 2000 (mattermost)
  install -d -o 2000 -g 2000 "$APP_DIR"/mm/{config,data,logs,plugins,client-plugins,bleve}
  cat > "$APP_DIR/compose.yaml" <<EOF
services:
  db:
    image: $DB_IMAGE
    restart: unless-stopped
    environment:
      POSTGRES_DB: mattermost
      POSTGRES_USER: mmuser
      POSTGRES_PASSWORD: \${DB_PASSWORD}
    volumes:
      - ./db:/var/lib/postgresql
    healthcheck:
      test: ["CMD", "pg_isready", "-h", "127.0.0.1", "-U", "mmuser", "-d", "mattermost"]
      interval: 5s
      retries: 60
  mattermost:
    image: $IMAGE
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
    environment:
      MM_SQLSETTINGS_DRIVERNAME: postgres
      MM_SQLSETTINGS_DATASOURCE: postgres://mmuser:\${DB_PASSWORD}@db:5432/mattermost?sslmode=disable&connect_timeout=10
      MM_SERVICESETTINGS_SITEURL: ${TINO_URL%/}
      MM_TEAMSETTINGS_ENABLEOPENSERVER: "false"
      MM_BLEVESETTINGS_INDEXDIR: /mattermost/bleve-indexes
    volumes:
      - ./mm/config:/mattermost/config
      - ./mm/data:/mattermost/data
      - ./mm/logs:/mattermost/logs
      - ./mm/plugins:/mattermost/plugins
      - ./mm/client-plugins:/mattermost/client/plugins
      - ./mm/bleve:/mattermost/bleve-indexes
    ports:
      - "127.0.0.1:$APP_PORT:8065"
EOF
}

mm_login() {
  jq -n --arg u "$ADMIN_USER" --arg p "$ADMIN_PW" '{login_id: $u, password: $p}' |
    api POST /api/v4/users/login -H 'Content-Type: application/json' -d @- | jq -e '.roles | split(" ") | index("system_admin")' >/dev/null
}

# Người dùng đầu tiên tạo qua POST /api/v4/users (không cần mời khi chưa có ai) thành system_admin.
app_setup() {
  mm_login 2>/dev/null && return 0
  jq -n --arg u "$ADMIN_USER" --arg p "$ADMIN_PW" --arg e "admin@$TINO_HOST" '{username: $u, password: $p, email: $e}' |
    api POST /api/v4/users -H 'Content-Type: application/json' -d @- >/dev/null ||
    refuse 'Mattermost trên VPS đã có người dùng từ trước, không tạo được tài khoản quản trị mới.'
  mm_login
}
