APP_VERSION=2.37.2
IMAGE='ghcr.io/advplyr/audiobookshelf:2.37.2@sha256:b897c33f05972fb1bf484f7487bc878fa91ec8691335c1db6e2929c3a7658efa'
APP_NOTE='Chép sách nói vào /opt/audiobookshelf/audiobooks, podcast vào /opt/audiobookshelf/podcasts trên VPS, rồi tạo thư viện trỏ tới /audiobooks hoặc /podcasts.'

app_files() {
  cat > "$APP_DIR/compose.yaml" <<EOF
services:
  audiobookshelf:
    image: $IMAGE
    restart: unless-stopped
    volumes:
      - ./config:/config
      - ./metadata:/metadata
      - ./audiobooks:/audiobooks
      - ./podcasts:/podcasts
    ports:
      - "127.0.0.1:$APP_PORT:80"
EOF
}

# POST /init tạo tài khoản root khi /status còn isInit=false (như trang khởi tạo lần đầu); rồi đăng nhập thử.
app_setup() {
  local cred
  cred=$(jq -n --arg u "$ADMIN_USER" --arg p "$ADMIN_PW" '{username: $u, password: $p}')
  if api GET /status | jq -e '.isInit != true' >/dev/null; then
    jq -c '{newRoot: .}' <<<"$cred" | api POST /init -H 'Content-Type: application/json' --data-binary @- >/dev/null
  fi
  api POST /login -H 'Content-Type: application/json' --data-binary @- <<<"$cred" | jq -e '.user.type == "root"' >/dev/null
}
