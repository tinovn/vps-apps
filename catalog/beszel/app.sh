APP_VERSION=0.21.2
HUB_IMAGE='henrygd/beszel:0.21.2@sha256:b0be90bd4aee2993fde763032a5098ce4386fba43cfe5031ec017b8d9e8c97a2'
AGENT_IMAGE='henrygd/beszel-agent:0.21.2@sha256:343254226ae57a5cc6f8c23c755b1464730aba2abc7043116a2e222711ec6e1a'
ADMIN_USER="admin@$TINO_HOST"  # Beszel đăng nhập bằng email
APP_NOTE='VPS này đã được theo dõi sẵn; thêm máy khác bằng nút "Add System" (cài beszel-agent trên máy đó).'

# Theo supplemental/docker/same-system/docker-compose.yml: hub + agent mạng host nối WebSocket vào hub qua 127.0.0.1.
# Agent nằm trong profile "agent": KEY/TOKEN chỉ có sau khi hub chạy, app_setup bật nó.
app_files() {
  envset ADMIN_PW "$ADMIN_PW"
  cat > "$APP_DIR/compose.yaml" <<EOF
services:
  beszel:
    image: $HUB_IMAGE
    container_name: beszel
    restart: unless-stopped
    environment:
      APP_URL: ${TINO_URL%/}
      # chỉ dùng ở migration đầu tiên (CSDL trống): tạo superuser và người dùng role admin
      USER_EMAIL: $ADMIN_USER
      USER_PASSWORD: \${ADMIN_PW}
    volumes:
      - ./beszel_data:/beszel_data
    ports:
      - "127.0.0.1:$APP_PORT:8090"
  beszel-agent:
    image: $AGENT_IMAGE
    container_name: beszel-agent
    profiles: [agent]
    restart: unless-stopped
    network_mode: host
    environment:
      HUB_URL: http://127.0.0.1:$APP_PORT
      KEY: \${AGENT_KEY:-}
      TOKEN: \${AGENT_TOKEN:-}
      # chỉ nối ra hub, không mở cổng SSH 45876
      DISABLE_SSH: "true"
    volumes:
      - ./agent_data:/var/lib/beszel-agent
      - /var/run/docker.sock:/var/run/docker.sock:ro
EOF
}

BZ_TOKEN=''
bz() { api "$1" "$2" -H "Authorization: $BZ_TOKEN" "${@:3}"; }
has_system() { bz GET '/api/collections/systems/records?perPage=1' | jq -e '.totalItems > 0' >/dev/null; }

app_setup() {
  local auth key
  # đăng nhập thử (mật khẩu đi qua biến môi trường của jq và stdin của curl)
  auth=$(BZ_PW=$ADMIN_PW jq -n --arg u "$ADMIN_USER" '{identity: $u, password: env.BZ_PW}' |
    api POST /api/collections/users/auth-with-password -H 'Content-Type: application/json' --data-binary @-)
  jq -e '.record.role == "admin"' <<<"$auth" >/dev/null
  BZ_TOKEN=$(jq -er .token <<<"$auth")

  # Agent giám sát chính VPS: token phổ dụng tạm (1 giờ) để agent tự đăng ký; hub lưu token vào bản ghi fingerprint
  # nên agent vẫn nối lại được khi token phổ dụng hết hạn.
  if ! has_system; then
    secret AGENT_TOKEN 40
    key=$(bz GET /api/beszel/info | jq -er '.key | select(startswith("ssh-"))')
    envset AGENT_KEY "$key"
    jq -n --arg t "$(envget AGENT_TOKEN)" '{token: $t, enable: 1, permanent: 0}' |
      bz POST /api/beszel/universal-token -H 'Content-Type: application/json' --data-binary @- >/dev/null
  fi
  compose --profile agent up -d beszel-agent
  for _ in $(seq 1 30); do
    has_system && return 0
    sleep 3
  done
  compose --profile agent logs --tail 20 beszel-agent 2>&1 | tail -c 3000
  APP_NOTE='beszel-agent chưa tự nối được vào hub: thêm VPS này bằng nút "Add System".'
}
