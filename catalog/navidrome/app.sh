APP_VERSION=0.64.2
IMAGE='deluan/navidrome:0.64.2@sha256:38dc2727bfcfd5ede290f8ada114fc90368146f265ae4701ddddbcbe2a44ee52'
APP_NOTE='Chép nhạc vào /opt/navidrome/music trên VPS rồi bấm quét thư viện trong giao diện; nghe trên điện thoại bằng ứng dụng hỗ trợ Subsonic (vd. Symfonium, Substreamer).'

app_files() {
  cat > "$APP_DIR/compose.yaml" <<EOF
services:
  navidrome:
    image: $IMAGE
    restart: unless-stopped
    environment:
      ND_ENABLEINSIGHTSCOLLECTOR: "false"
    volumes:
      - ./data:/data
      - ./music:/music:ro
    ports:
      - "127.0.0.1:$APP_PORT:4533"
EOF
}

# POST /auth/createAdmin chỉ nhận khi chưa có người dùng nào (403 nếu đã có); rồi đăng nhập thử.
app_setup() {
  local cred
  cred=$(jq -n --arg u "$ADMIN_USER" --arg p "$ADMIN_PW" '{username: $u, password: $p}')
  if ! api POST /auth/login -H 'Content-Type: application/json' --data-binary @- <<<"$cred" >/dev/null 2>&1; then
    api POST /auth/createAdmin -H 'Content-Type: application/json' --data-binary @- <<<"$cred" >/dev/null
  fi
  api POST /auth/login -H 'Content-Type: application/json' --data-binary @- <<<"$cred" | jq -e '.isAdmin == true' >/dev/null
}
