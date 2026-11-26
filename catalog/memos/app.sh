APP_VERSION=26.11.1
IMAGE='neosmemo/memos:26.11.1@sha256:5dcd6e6b973a55b964f2fe2ccdaa33319463ab448a23404ebb5d2acbd19299ba'
APP_NOTE='Đăng ký tự do đang tắt; quản trị tạo thêm người dùng ở Settings → Members.'

app_files() {
  cat > "$APP_DIR/compose.yaml" <<EOF
services:
  memos:
    image: $IMAGE
    restart: unless-stopped
    environment:
      MEMOS_INSTANCE_URL: ${TINO_URL%/}
    volumes:
      - ./data:/var/opt/memos
    ports:
      - "127.0.0.1:$APP_PORT:5230"
EOF
}

memos_signin() {
  jq -n --arg u "$ADMIN_USER" --arg p "$ADMIN_PW" '{passwordCredentials: {username: $u, password: $p}}' |
    api POST /api/auth/signin -H 'Content-Type: application/json' -d @- | jq -er '.accessToken'
}

# Người đầu tiên tạo qua POST /api/users (không cần đăng nhập) thành ADMIN (server/api/user_service.go CreateUser),
# rồi tắt đăng ký tự do: UpdateInstanceSetting thay cả GENERAL nên đọc bản hiện tại, đổi một trường, ghi lại.
app_setup() {
  local tok gen
  if ! tok=$(memos_signin 2>/dev/null); then
    jq -n --arg u "$ADMIN_USER" --arg p "$ADMIN_PW" '{username: $u, password: $p}' |
      api POST /api/users -H 'Content-Type: application/json' -d @- | jq -e '.role == "ADMIN"' >/dev/null ||
      refuse 'Memos trên VPS đã có người dùng từ trước, không tạo được tài khoản quản trị mới.'
    tok=$(memos_signin)
  fi
  gen=$(api GET /api/instance/settings/GENERAL -K - <<<"header = \"Authorization: Bearer $tok\"" |
    jq -c '.generalSetting.disallowUserRegistration = true')
  api PATCH /api/instance/settings/GENERAL -H 'Content-Type: application/json' -d "$gen" -K - <<<"header = \"Authorization: Bearer $tok\"" |
    jq -e '.generalSetting.disallowUserRegistration == true' >/dev/null
}
