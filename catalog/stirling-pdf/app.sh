APP_VERSION=3.3.0
IMAGE='stirlingtools/stirling-pdf:3.3.0@sha256:ed7b1775c6706b5e5ea24fa6155f078eff1027bd35a17d21834e4407036025e6'
WAIT_SECS=600  # Java + LibreOffice khởi động chậm (healthcheck của image chờ 120 s)
APP_NOTE='Quản trị thêm người dùng trong phần Settings; bản tự host miễn phí cho tối đa 5 người dùng (giới hạn của Stirling PDF).'

app_files() {
  envset ADMIN_PW "$ADMIN_PW"
  # Đăng nhập luôn bật; tài khoản quản trị đầu tiên lấy từ security.initialLogin khi CSDL chưa có ai (InitialSecuritySetup)
  cat > "$APP_DIR/compose.yaml" <<EOF2
services:
  stirling-pdf:
    image: $IMAGE
    restart: unless-stopped
    environment:
      SECURITY_ENABLELOGIN: "true"
      SECURITY_INITIALLOGIN_USERNAME: $ADMIN_USER
      SECURITY_INITIALLOGIN_PASSWORD: \${ADMIN_PW}
      SYSTEM_DEFAULTLOCALE: vi-VN
    volumes:
      - ./configs:/configs
      - ./logs:/logs
      - ./storage:/storage
    ports:
      - "127.0.0.1:$APP_PORT:8080"
EOF2
}

# Đăng nhập thử: POST /api/v1/auth/login (AuthController), sai → 401
app_setup() {
  jq -n --arg u "$ADMIN_USER" --arg p "$ADMIN_PW" '{username: $u, password: $p}' |
    api POST /api/v1/auth/login -H 'Content-Type: application/json' -d @- >/dev/null ||
    refuse 'Stirling PDF trên VPS đã có tài khoản quản trị từ trước với mật khẩu khác.'
}
