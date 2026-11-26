APP_VERSION=3.5.0
IMAGE='ghcr.io/umami-software/umami:3.5.0@sha256:b64f40400d77bcadd39cf5c62a1e368c99524ca442024f96e1133355a19a5dbc'
DB_IMAGE='postgres:17.12-alpine@sha256:a77aa70e641402a21411b92b721c58d10f23b50ae5fdd2333efd22d166e1e5f7'

app_files() {
  secret DB_PASSWORD
  secret APP_SECRET 64
  cat > "$APP_DIR/compose.yaml" <<EOF
services:
  db:
    image: $DB_IMAGE
    restart: unless-stopped
    environment:
      POSTGRES_DB: umami
      POSTGRES_USER: umami
      POSTGRES_PASSWORD: \${DB_PASSWORD}
    volumes:
      - ./db:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U umami -d umami"]
      interval: 5s
      retries: 60
  umami:
    image: $IMAGE
    restart: unless-stopped
    init: true
    depends_on:
      db:
        condition: service_healthy
    environment:
      DATABASE_URL: postgresql://umami:\${DB_PASSWORD}@db:5432/umami
      APP_SECRET: \${APP_SECRET}
    ports:
      - "127.0.0.1:$APP_PORT:3000"
EOF
}

# umami_login MẬT_KHẨU → token, rỗng nếu sai
umami_login() {
  jq -n --arg u "$ADMIN_USER" --arg p "$1" '{username: $u, password: $p}' |
    api POST /api/auth/login -H 'Content-Type: application/json' --data-binary @- 2>/dev/null | jq -r '.token // empty' || true
}

# Migration của Umami tạo sẵn admin / umami: đổi ngay sang mật khẩu riêng (trước khi mở HTTPS) rồi đăng nhập thử.
app_setup() {
  local tok
  tok=$(umami_login "$ADMIN_PW")
  if [ -z "$tok" ]; then
    tok=$(umami_login umami)
    [ -n "$tok" ] || refuse 'Umami trên VPS đã có tài khoản admin với mật khẩu khác.'
    # token gắn với băm mật khẩu cũ: hết hiệu lực ngay sau lệnh đổi mật khẩu
    jq -n --arg p "$ADMIN_PW" '{currentPassword: "umami", newPassword: $p}' |
      api POST /api/me/password -H 'Content-Type: application/json' -H "Authorization: Bearer $tok" --data-binary @- >/dev/null
    tok=$(umami_login "$ADMIN_PW")
  fi
  [ -n "$tok" ] || die 'Không đăng nhập thử được vào Umami bằng mật khẩu mới.'
}
