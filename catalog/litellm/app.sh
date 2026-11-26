APP_VERSION=1.109.1
IMAGE='ghcr.io/berriai/litellm-database:v1.109.1@sha256:932c54440654f8f8466a85887612d95dcfb04ae2fc01257844332f4bf3b96986'
DB_IMAGE='postgres:16.16-alpine@sha256:81e77a4833487b8132fe4b00bedd39dc3f74b8641e387f19312a48f7de218c2e'
WAIT_SECS=600  # lần đầu chạy prisma migrate trên Postgres trước khi nghe cổng
APP_NOTE='Trang quản trị ở /ui (thêm mô hình, tạo khoá ảo cho từng ứng dụng); khoá master API (LITELLM_MASTER_KEY) nằm trong /opt/litellm/.env, không chia sẻ khoá này. Khi chia sẻ quyền gọi mô hình cho người khác, tuân thủ điều khoản của nhà cung cấp mô hình.'

app_files() {
  secret DB_PASSWORD
  # khoá master phải bắt đầu bằng "sk-"; LITELLM_SALT_KEY mã hoá khoá nhà cung cấp lưu trong DB: không được đổi sau khi đã dùng
  grep -q '^LITELLM_MASTER_KEY=sk-.' "$APP_DIR/.env" 2>/dev/null || envset LITELLM_MASTER_KEY "sk-$(rand 48)"
  grep -q '^LITELLM_SALT_KEY=sk-.' "$APP_DIR/.env" 2>/dev/null || envset LITELLM_SALT_KEY "sk-$(rand 48)"
  envset ADMIN_PW "$ADMIN_PW"
  cat > "$APP_DIR/compose.yaml" <<EOF
services:
  db:
    image: $DB_IMAGE
    restart: unless-stopped
    environment:
      POSTGRES_DB: litellm
      POSTGRES_USER: litellm
      POSTGRES_PASSWORD: \${DB_PASSWORD}
    volumes:
      - ./db:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -d litellm -U litellm"]
      interval: 5s
      retries: 60
  litellm:
    image: $IMAGE
    container_name: litellm
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
    environment:
      DATABASE_URL: postgresql://litellm:\${DB_PASSWORD}@db:5432/litellm
      LITELLM_MASTER_KEY: \${LITELLM_MASTER_KEY}
      LITELLM_SALT_KEY: \${LITELLM_SALT_KEY}
      STORE_MODEL_IN_DB: "True"
      UI_USERNAME: $ADMIN_USER
      UI_PASSWORD: \${ADMIN_PW}
      PROXY_BASE_URL: ${TINO_URL%/}
    ports:
      - "127.0.0.1:$APP_PORT:4000"
EOF
}

# Quản trị là UI_USERNAME / UI_PASSWORD (không có bước tạo): đăng nhập thử như trang /ui, rồi kiểm khoá master.
app_setup() {
  local try
  for try in 1 2 3 4 5 6; do  # /health/liveliness trả lời trước khi Prisma nối xong DB: thử lại
    if jq -n --arg u "$ADMIN_USER" --arg p "$ADMIN_PW" '{username: $u, password: $p}' |
      api POST /v2/login -H 'Content-Type: application/json' --data-binary @- | jq -e '.token | length > 0' >/dev/null; then
      break
    fi
    [ "$try" -lt 6 ] || exit 1
    sleep 10
  done
  api GET /v1/models -K - <<<"header = \"Authorization: Bearer $(envget LITELLM_MASTER_KEY)\"" | jq -e '.data | type == "array"' >/dev/null
}
