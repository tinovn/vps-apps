APP_VERSION=0.13.2  # bản ổn định mới nhất; dòng v1.0.0-rc.* là bản thử
IMAGE='calciumion/new-api:v0.13.2@sha256:0c6aa7afce4747f0fc4fab9c7934d7c2e4b69fda6844065acca6a5e1bf258506'
APP_NOTE='Thêm khoá API của nhà cung cấp mô hình ở mục Kênh (Channels); khi chia sẻ khoá hay bán lại cho người khác, tuân thủ điều khoản của nhà cung cấp đó. Đăng ký tự do đang tắt, quản trị tạo thêm người dùng.'

app_files() {
  secret SESSION_SECRET 64  # khoá phiên; CRYPTO_SECRET mặc định lấy theo khoá này
  cat > "$APP_DIR/compose.yaml" <<EOF
services:
  new-api:
    image: $IMAGE
    container_name: new-api
    restart: unless-stopped
    environment:
      SESSION_SECRET: \${SESSION_SECRET}
      TZ: Asia/Ho_Chi_Minh
    volumes:
      - ./data:/data
    ports:
      - "127.0.0.1:$APP_PORT:3000"
EOF
}

# Root đầu tiên tạo qua POST /api/setup (như trình hướng dẫn trên web), đăng nhập thử, rồi tắt đăng ký tự do.
app_setup() {
  local out id jar
  if [ "$(api GET /api/setup | jq -r '.data.status')" != true ]; then
    jq -n --arg u "$ADMIN_USER" --arg p "$ADMIN_PW" \
      '{username: $u, password: $p, confirmPassword: $p, SelfUseModeEnabled: false, DemoSiteEnabled: false}' |
      api POST /api/setup -H 'Content-Type: application/json' --data-binary @- | jq -e '.success == true' >/dev/null
  fi
  jar=$(mktemp)
  out=$(jq -n --arg u "$ADMIN_USER" --arg p "$ADMIN_PW" '{username: $u, password: $p}' |
    api POST /api/user/login -c "$jar" -H 'Content-Type: application/json' --data-binary @-)
  # lỗi đăng nhập vẫn là HTTP 200 với success=false; root có role 100
  id=$(jq -r 'select(.success == true and .data.role == 100) | .data.id' <<<"$out")
  [ -n "$id" ] || die "Đăng nhập thử New API thất bại: $(jq -r '.message' <<<"$out")"
  for kv in RegisterEnabled=false "ServerAddress=${TINO_URL%/}"; do
    jq -n --arg k "${kv%%=*}" --arg v "${kv#*=}" '{key: $k, value: $v}' |
      api PUT /api/option/ -b "$jar" -H "New-Api-User: $id" -H 'Content-Type: application/json' --data-binary @- |
      jq -e '.success == true' >/dev/null
  done
  rm -f "$jar"
}
