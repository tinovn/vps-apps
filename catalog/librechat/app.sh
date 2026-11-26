APP_VERSION=0.8.8
IMAGE='ghcr.io/librechat-ai/librechat:v0.8.8@sha256:5b706bcee1ca154a1e2987303aaeca0eb27f97919cccee4bb604226c2f8abf61'
MONGO_IMAGE='mongo:8.0.20@sha256:098862b1339f031900ca66cf8fef799e616d6324fa41b9a263f2ec899552c1ef'
MEILI_IMAGE='getmeili/meilisearch:v1.35.1@sha256:8b57fc3c7f46535ddef3828df1538465ac19d892eb57c9a10da6df0880bd5856'
ADMIN_USER="admin@$TINO_HOST"  # LibreChat đăng nhập bằng email
APP_NOTE='Mỗi người dùng tự nhập khoá API (OpenAI, Anthropic, Google) khi chọn mô hình; đăng ký tự do đang tắt, quản trị tạo thêm người dùng bằng lệnh create-user trong container.'

# bí mật dạng hex đúng độ dài byte (CREDS_KEY 32 byte, CREDS_IV 16 byte), tạo một lần
hexsecret() { grep -q "^$1=." "$APP_DIR/.env" 2>/dev/null || envset "$1" "$(openssl rand -hex "$2")"; }

app_files() {
  # MongoDB 5+ cần CPU có AVX; CPU ảo kiểu x86-64-v2 không có
  grep -qw avx /proc/cpuinfo || refuse 'LibreChat cần CPU có tập lệnh AVX (MongoDB 8), CPU của VPS không có.'
  hexsecret CREDS_KEY 32
  hexsecret CREDS_IV 16
  secret JWT_SECRET 64
  secret JWT_REFRESH_SECRET 64
  secret MEILI_MASTER_KEY 32
  install -d -m 755 -o 1000 -g 1000 "$APP_DIR/images" "$APP_DIR/uploads" "$APP_DIR/logs"
  cat > "$APP_DIR/compose.yaml" <<EOF
services:
  api:
    image: $IMAGE
    container_name: librechat
    restart: unless-stopped
    depends_on:
      - mongodb
      - meilisearch
    environment:
      HOST: 0.0.0.0
      PORT: "3080"
      NODE_ENV: production
      MONGO_URI: mongodb://mongodb:27017/LibreChat
      MEILI_HOST: http://meilisearch:7700
      MEILI_MASTER_KEY: \${MEILI_MASTER_KEY}
      SEARCH: "true"
      DOMAIN_CLIENT: ${TINO_URL%/}
      DOMAIN_SERVER: ${TINO_URL%/}
      TRUST_PROXY: "1"
      NO_INDEX: "true"
      CREDS_KEY: \${CREDS_KEY}
      CREDS_IV: \${CREDS_IV}
      JWT_SECRET: \${JWT_SECRET}
      JWT_REFRESH_SECRET: \${JWT_REFRESH_SECRET}
      ALLOW_EMAIL_LOGIN: "true"
      ALLOW_REGISTRATION: "false"
      ALLOW_SOCIAL_LOGIN: "false"
      ALLOW_SOCIAL_REGISTRATION: "false"
      ALLOW_PASSWORD_RESET: "false"
      ALLOW_UNVERIFIED_EMAIL_LOGIN: "true"
      OPENAI_API_KEY: user_provided
      ANTHROPIC_API_KEY: user_provided
      GOOGLE_KEY: user_provided
    volumes:
      - ./images:/app/client/public/images
      - ./uploads:/app/uploads
      - ./logs:/app/logs
    ports:
      - "127.0.0.1:$APP_PORT:3080"
  mongodb:
    image: $MONGO_IMAGE
    restart: unless-stopped
    command: mongod --noauth
    volumes:
      - ./data-node:/data/db
  meilisearch:
    image: $MEILI_IMAGE
    restart: unless-stopped
    environment:
      MEILI_MASTER_KEY: \${MEILI_MASTER_KEY}
      MEILI_NO_ANALYTICS: "true"
      MEILI_ENV: production
    volumes:
      - ./meili_data:/meili_data
EOF
}

# trả 0 khi đăng nhập được bằng email + mật khẩu quản trị (mật khẩu đi qua stdin của curl)
lc_login() {
  jq -n --arg e "$ADMIN_USER" --arg p "$ADMIN_PW" '{email: $e, password: $p}' \
    | api POST /api/auth/login -H 'Content-Type: application/json' --data-binary @- | jq -e '.token | length > 0' >/dev/null
}

app_setup() {
  lc_login 2>/dev/null && return 0
  # create-user hỏi mật khẩu qua readline khi không có tham số thứ 4: mật khẩu đi qua stdin, không lên dòng lệnh
  # bỏ stdout/stderr: logger của registerUser có thể ghi cả đối tượng user (kèm mật khẩu) khi lỗi
  docker exec -i librechat node config/create-user.js "$ADMIN_USER" Admin admin --email-verified=true <<<"$ADMIN_PW" >/dev/null 2>&1 \
    || die 'Không tạo được quản trị LibreChat (có thể đã có người dùng admin với mật khẩu khác); xem docker logs librechat.'
  lc_login
}
