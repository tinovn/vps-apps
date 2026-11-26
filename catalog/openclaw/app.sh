APP_VERSION=2026.11.4
IMAGE='ghcr.io/openclaw/openclaw:2026.11.4@sha256:f019ffc78c8866dc38c5e965e748a474989c0bdd132ed307a87ae606d829bd26'
# Control UI từ Internet cần ghép đôi trình duyệt (pairing): với mật khẩu/token phải duyệt bằng CLI trên VPS.
# Dùng chế độ trusted-proxy: Caddy hỏi admin/mật khẩu (basic auth) rồi gửi danh tính trong X-Forwarded-User,
# gateway tự duyệt trình duyệt đã qua Caddy (deviceAutoApprove) và cấp quyền quản trị cho đúng người dùng đó.
APP_AUTH=basic
CADDY_EXTRA=$'\trequest_header X-Forwarded-User {http.auth.user.id}\n'
WAIT_SECS=420
APP_NOTE='Vào Control UI mục Models nhập khoá API mô hình, mục Channels nối Telegram/Zalo; người lạ nhắn bot phải được duyệt (pairing) trong Control UI.'
OC_NET=172.31.255  # mạng riêng của compose; Caddy → docker-proxy → gateway đi từ .1 (trusted proxy duy nhất)

app_files() {
  secret GATEWAY_PASSWORD 48  # mật khẩu nội bộ cho CLI trong container (openclaw devices …), không mở ra ngoài
  install -d -m 700 -o 1000 -g 1000 "$APP_DIR/state" "$APP_DIR/auth-secrets"
  if [ ! -s "$APP_DIR/state/openclaw.json" ]; then
    # Chỉ viết lần đầu: sau đó khách đổi cấu hình trong Control UI. Không bật kênh nào; DM mặc định là pairing.
    jq -n --arg origin "https://$TINO_HOST" --arg proxy "$OC_NET.1" --arg user "$ADMIN_USER" '{
      gateway: {
        mode: "local", bind: "lan", port: 18789,
        publicOrigin: $origin,
        trustedProxies: [$proxy],
        auth: {
          mode: "trusted-proxy",
          trustedProxy: {
            userHeader: "x-forwarded-user",
            requiredHeaders: ["x-forwarded-proto", "x-forwarded-host"],
            allowUsers: [$user],
            deviceAutoApprove: { enabled: true }
          },
          identityScopes: { ($user): ["operator.admin"] }
        }
      }
    }' > "$APP_DIR/state/openclaw.json"
    chown 1000:1000 "$APP_DIR/state/openclaw.json"
    chmod 600 "$APP_DIR/state/openclaw.json"
  fi
  # bind lan là 0.0.0.0 trong mạng của container (Docker không tới được loopback của container);
  # trên VPS chỉ có 127.0.0.1:APP_PORT.
  cat > "$APP_DIR/compose.yaml" <<EOF
services:
  openclaw:
    image: $IMAGE
    container_name: openclaw
    restart: unless-stopped
    environment:
      OPENCLAW_GATEWAY_PASSWORD: \${GATEWAY_PASSWORD}
      OPENCLAW_DISABLE_BONJOUR: "1"
    volumes:
      - ./state:/home/node/.openclaw
      - ./auth-secrets:/home/node/.config/openclaw
    cap_drop:
      - NET_RAW
      - NET_ADMIN
    security_opt:
      - no-new-privileges:true
    ports:
      - "127.0.0.1:$APP_PORT:18789"
networks:
  default:
    ipam:
      config:
        - subnet: $OC_NET.0/24
          gateway: $OC_NET.1
EOF
}

# Đăng nhập thử như Caddy: có X-Forwarded-User thì đọc được cấu hình Control UI, không có thì bị từ chối (401/403).
app_setup() {
  local h=(-H 'X-Forwarded-Proto: https' -H "X-Forwarded-Host: $TINO_HOST" -H 'X-Forwarded-For: 192.0.2.10') ok='' code
  for _ in $(seq 1 40); do  # agent còn chuẩn bị cơ sở dữ liệu sau khi /healthz đã trả lời
    if api GET /control-ui-config.json "${h[@]}" -H "X-Forwarded-User: $ADMIN_USER" | jq -e . >/dev/null; then
      ok=1
      break
    fi
    sleep 3
  done
  [ -n "$ok" ] || exit 1
  code=$(curl -s -o /dev/null -w '%{http_code}' "${h[@]}" "http://127.0.0.1:$APP_PORT/control-ui-config.json")
  case "$code" in 401 | 403) ;; *) die "OpenClaw trả HTTP $code cho Control UI khi chưa đăng nhập." ;; esac
}
