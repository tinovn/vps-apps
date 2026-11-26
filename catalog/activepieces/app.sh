APP_VERSION=0.93.0
IMAGE='ghcr.io/activepieces/activepieces:0.93.0@sha256:151c2a4326c30a6a8086297136644da9b58072212c35bca7c87dcb5724e7d687'
DB_IMAGE='pgvector/pgvector:0.8.7-pg16@sha256:484e838076e04939d27d3e176e91c86eea96236126023be8d3059761122e579f'
REDIS_IMAGE='redis:7.4.12-alpine@sha256:7f7d30b7fdd09467bac58198a1f166dd69789d348d4fe859cccb20e0cf287fbe'
ADMIN_USER="admin@$TINO_HOST"  # Activepieces đăng nhập bằng email
WAIT_SECS=600
APP_NOTE='Người dùng mới chỉ vào được khi quản trị mời (Platform Admin → Users).'

app_files() {
  secret DB_PASSWORD
  secret JWT_SECRET 64
  # AP_ENCRYPTION_KEY: 32 ký tự hex (tools/deploy.sh: openssl rand -hex 16); mất khoá này thì không giải mã được kết nối đã lưu
  grep -q '^AP_ENCRYPTION_KEY=.' "$APP_DIR/.env" 2>/dev/null || envset AP_ENCRYPTION_KEY "$(openssl rand -hex 16)"
  cat > "$APP_DIR/compose.yaml" <<EOF
services:
  postgres:
    image: $DB_IMAGE
    restart: unless-stopped
    environment:
      POSTGRES_DB: activepieces
      POSTGRES_USER: postgres
      POSTGRES_PASSWORD: \${DB_PASSWORD}
    volumes:
      - ./postgres:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U postgres -d activepieces"]
      interval: 5s
      retries: 60
  redis:
    image: $REDIS_IMAGE
    restart: unless-stopped
    volumes:
      - ./redis:/data
  # một container chạy cả app và worker (AP_CONTAINER_TYPE mặc định WORKER_AND_APP)
  app:
    image: $IMAGE
    container_name: activepieces
    restart: unless-stopped
    depends_on:
      postgres:
        condition: service_healthy
      redis:
        condition: service_started
    environment:
      AP_ENGINE_EXECUTABLE_PATH: dist/packages/engine/main.js
      AP_ENCRYPTION_KEY: \${AP_ENCRYPTION_KEY}
      AP_JWT_SECRET: \${JWT_SECRET}
      AP_ENVIRONMENT: prod
      AP_FRONTEND_URL: ${TINO_URL%/}
      AP_EXECUTION_MODE: UNSANDBOXED
      AP_POSTGRES_DATABASE: activepieces
      AP_POSTGRES_HOST: postgres
      AP_POSTGRES_PORT: "5432"
      AP_POSTGRES_USERNAME: postgres
      AP_POSTGRES_PASSWORD: \${DB_PASSWORD}
      AP_REDIS_HOST: redis
      AP_REDIS_PORT: "6379"
      AP_TELEMETRY_ENABLED: "false"
      AP_TEMPLATES_SOURCE_URL: https://cloud.activepieces.com/api/v1/flow-templates
    volumes:
      - ./cache:/usr/src/app/cache
    ports:
      - "127.0.0.1:$APP_PORT:80"
EOF
}

# Tài khoản đăng ký đầu tiên là quản trị nền tảng; sau đó đăng ký chỉ theo lời mời (AP_ALLOW_OPEN_SIGN_UP không bật).
app_setup() {
  local signin signup
  signin=$(jq -n --arg e "$ADMIN_USER" --arg p "$ADMIN_PW" '{email: $e, password: $p}')
  if ! api POST /api/v1/authentication/sign-in -H 'Content-Type: application/json' --data-binary @- <<<"$signin" >/dev/null 2>&1; then
    signup=$(jq -n --arg e "$ADMIN_USER" --arg p "$ADMIN_PW" \
      '{email: $e, password: $p, firstName: "Admin", lastName: "Tino", trackEvents: false, newsLetter: false}')
    api POST /api/v1/authentication/sign-up -H 'Content-Type: application/json' --data-binary @- <<<"$signup" >/dev/null
  fi
  api POST /api/v1/authentication/sign-in -H 'Content-Type: application/json' --data-binary @- <<<"$signin" |
    jq -e '.platformRole == "ADMIN" and (.token | length > 0)' >/dev/null
}
