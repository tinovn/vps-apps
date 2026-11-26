APP_VERSION=1.13.2
IMAGE='langflowai/langflow:1.13.2@sha256:4cfba8c49c4dba081964f9096bc8b9169f99f7c720000a9563a2fd1296a35e9f'
DB_IMAGE='postgres:16.16-trixie@sha256:dd2bf3ce2dc83a81674cf7f217fcfd8a5009a4b325dda5b843bfee82a06cff6f'
WAIT_SECS=600
APP_NOTE='Đăng ký tự do đang tắt; quản trị tạo thêm người dùng trong Admin Page.'

app_files() {
  secret DB_PASSWORD
  secret SECRET_KEY 64
  envset ADMIN_PW "$ADMIN_PW"
  # image chạy bằng uid 1000 (nhóm 0)
  install -d -m 755 -o 1000 -g 0 "$APP_DIR/data"
  cat > "$APP_DIR/compose.yaml" <<EOF
services:
  db:
    image: $DB_IMAGE
    restart: unless-stopped
    environment:
      POSTGRES_DB: langflow
      POSTGRES_USER: langflow
      POSTGRES_PASSWORD: \${DB_PASSWORD}
    volumes:
      - ./db:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U langflow -d langflow"]
      interval: 5s
      retries: 60
  langflow:
    image: $IMAGE
    container_name: langflow
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
    environment:
      LANGFLOW_DATABASE_URL: postgresql://langflow:\${DB_PASSWORD}@db:5432/langflow
      LANGFLOW_CONFIG_DIR: /app/langflow
      LANGFLOW_SECRET_KEY: \${SECRET_KEY}
      LANGFLOW_AUTO_LOGIN: "false"
      # tạo superuser lúc khởi động nếu chưa có; đã có thì giữ mật khẩu cũ
      LANGFLOW_SUPERUSER: $ADMIN_USER
      LANGFLOW_SUPERUSER_PASSWORD: \${ADMIN_PW}
      LANGFLOW_ENABLE_SIGNUP: "false"
      LANGFLOW_NEW_USER_IS_ACTIVE: "false"
      LANGFLOW_ACCESS_SECURE: "true"
      LANGFLOW_REFRESH_SECURE: "true"
      LANGFLOW_DO_NOT_TRACK: "true"
    volumes:
      - ./data:/app/langflow
    ports:
      - "127.0.0.1:$APP_PORT:7860"
EOF
}

app_setup() {
  local tok
  tok=$(api POST /api/v1/login -K - <<EOF | jq -r '.access_token // empty'
data-urlencode = "username=$ADMIN_USER"
data-urlencode = "password=$ADMIN_PW"
EOF
)
  [ -n "$tok" ] || die 'Langflow: đăng nhập thử bằng tài khoản quản trị không được.'
  api GET /api/v1/users/whoami -K - <<<"header = \"Authorization: Bearer $tok\"" | jq -e '.is_superuser == true' >/dev/null
}
