APP_VERSION=2026.10.1
IMAGE='nocodb/nocodb:2026.10.1@sha256:8c2dd06896d95e750d55010e529972c22c1ee73b22dce321b1d2de2e7d5cd6ae'
DB_IMAGE='postgres:17.12-alpine@sha256:a77aa70e641402a21411b92b721c58d10f23b50ae5fdd2333efd22d166e1e5f7'
ADMIN_USER="admin@$TINO_HOST"  # NocoDB đăng nhập bằng email
WAIT_SECS=600
APP_NOTE='Đăng ký tự do đã tắt: quản trị mời thêm thành viên trong Account → Users.'

app_files() {
  secret DB_PASSWORD
  cat > "$APP_DIR/compose.yaml" <<EOF
services:
  db:
    image: $DB_IMAGE
    restart: unless-stopped
    environment:
      POSTGRES_USER: nocodb
      POSTGRES_PASSWORD: \${DB_PASSWORD}
      POSTGRES_DB: nocodb
    volumes:
      - ./db:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U nocodb -d nocodb"]
      interval: 5s
      retries: 60
  nocodb:
    image: $IMAGE
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
    environment:
      NC_DB: "pg://db:5432?u=nocodb&p=\${DB_PASSWORD}&d=nocodb"
      NC_SITE_URL: ${TINO_URL%/}
      NC_DISABLE_TELE: "true"
      NC_SECURE_ATTACHMENTS: "true"
    volumes:
      - ./data:/usr/app/data
    ports:
      - "127.0.0.1:$APP_PORT:8080"
EOF
}

# Không dùng NC_ADMIN_EMAIL/NC_ADMIN_PASSWORD: NocoDB đặt lại mật khẩu theo biến đó mỗi lần khởi động.
# Người đăng ký đầu tiên thành super admin (lúc cổng chỉ mở ở 127.0.0.1), rồi bật "chỉ đăng ký qua lời mời".
app_setup() {
  local cred tok
  cred=$(jq -n --arg e "$ADMIN_USER" --arg p "$ADMIN_PW" '{email: $e, password: $p}')
  if api GET /api/v1/meta/nocodb/info | jq -e '.firstUser == true' >/dev/null; then
    jq -c '. + {ignore_subscribe: true}' <<<"$cred" |
      api POST /api/v1/auth/user/signup -H 'Content-Type: application/json' --data-binary @- >/dev/null
  fi
  tok=$(api POST /api/v1/auth/user/signin -H 'Content-Type: application/json' --data-binary @- <<<"$cred" | jq -er .token)
  api GET /api/v1/auth/user/me -H "xc-auth: $tok" | jq -e '.roles.super == true' >/dev/null
  # mặc định invite_only_signup=false: ai cũng tự đăng ký được (vai trò viewer)
  api POST /api/v1/app-settings -H "xc-auth: $tok" -H 'Content-Type: application/json' \
    -d '{"invite_only_signup": true}' >/dev/null
}
