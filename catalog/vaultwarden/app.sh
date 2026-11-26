APP_VERSION=1.37.5
IMAGE='vaultwarden/server:1.37.5@sha256:4fe17f415f90087377d37c755e0ea3cf189dcc6794e49cdd2a9adbb4937d9e1f'
APP_APT=(argon2)
APP_NOTE='Vào trang /admin bằng mật khẩu trong tệp thông tin để mời người dùng (nhập email), người được mời tự đăng ký tại trang chủ; đăng ký tự do đang tắt.'
LOGIN_NOTE='Mật khẩu trong /root/tino-app.txt trên VPS là admin token của trang /admin (không phải tài khoản kho mật khẩu): vào /admin mời email của bạn rồi tự đăng ký ở trang chủ.'

app_files() {
  # ADMIN_TOKEN dạng Argon2id PHC của mật khẩu quản trị (wiki Vaultwarden "Enabling admin page", preset bitwarden);
  # đọc qua ADMIN_TOKEN_FILE để tránh ký tự $ trong .env của compose. Chỉ sinh một lần.
  if [ ! -s "$APP_DIR/admin_token" ]; then
    (
      umask 077
      printf '%s' "$ADMIN_PW" | argon2 "$(rand 22)" -id -e -k 65540 -t 3 -p 4 > "$APP_DIR/admin_token"
    )
  fi
  cat > "$APP_DIR/compose.yaml" <<EOF
services:
  vaultwarden:
    image: $IMAGE
    restart: unless-stopped
    environment:
      DOMAIN: ${TINO_URL%/}
      SIGNUPS_ALLOWED: "false"
      INVITATIONS_ALLOWED: "true"
      ADMIN_TOKEN_FILE: /run/secrets/admin_token
      # Caddy gửi IP khách ở X-Forwarded-For (mặc định Vaultwarden đọc X-Real-IP)
      IP_HEADER: X-Forwarded-For
    volumes:
      - ./data:/data
      - ./admin_token:/run/secrets/admin_token:ro
    ports:
      - "127.0.0.1:$APP_PORT:80"
EOF
}

# Đăng nhập thử trang /admin: token đúng → 200, sai → 401 (src/api/admin.rs post_admin_login)
app_setup() {
  api POST /admin -K - <<<"data-urlencode = \"token=$ADMIN_PW\"" >/dev/null
}
