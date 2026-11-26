APP_VERSION=1.20.2
IMAGE='qdrant/qdrant:v1.20.2@sha256:d277592721d2e3b73f9b797b53cf05e6a5bb2134f6d13fdbda4ca51782afbcac'
APP_NOTE='Bảng điều khiển ở /dashboard (nhập cùng khoá). gRPC (6334) không mở ra ngoài.'
LOGIN_NOTE='Qdrant không có tài khoản: gọi REST API kèm header "api-key: <mật khẩu>", mật khẩu nằm trong /root/tino-app.txt trên VPS.'

app_files() {
  envset ADMIN_PW "$ADMIN_PW"
  cat > "$APP_DIR/compose.yaml" <<EOF
services:
  qdrant:
    image: $IMAGE
    container_name: qdrant
    restart: unless-stopped
    environment:
      QDRANT__SERVICE__API_KEY: \${ADMIN_PW}
      QDRANT__TELEMETRY_DISABLED: "true"
    volumes:
      - ./storage:/qdrant/storage
      - ./snapshots:/qdrant/snapshots
    ports:
      - "127.0.0.1:$APP_PORT:6333"
EOF
}

# Không có tài khoản để tạo: kiểm khoá API (qua stdin của curl) và kiểm thiếu khoá thì bị từ chối.
app_setup() {
  api GET /collections -K - <<<"header = \"api-key: $ADMIN_PW\"" | jq -e '.status == "ok"' >/dev/null
  [ "$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:$APP_PORT/collections")" = 401 ] || die 'Qdrant chưa bật khoá API.'
}
