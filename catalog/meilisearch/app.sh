APP_VERSION=1.57.0
IMAGE='getmeili/meilisearch:v1.57.0@sha256:91bf09897482c17205c8faeca8daa8d57999fb9de20d862763cdfa92ba4ec790'
APP_NOTE='Nên tạo API key riêng cho từng ứng dụng thay vì dùng khoá master.'
LOGIN_NOTE='Meilisearch không có trang đăng nhập: gọi API kèm header "Authorization: Bearer <khoá master>", khoá master là mật khẩu trong /root/tino-app.txt trên VPS.'

app_files() {
  # khoá master = mật khẩu quản trị (MEILI_ENV=production đòi ít nhất 16 byte; mật khẩu sinh ra dài 24)
  envset ADMIN_PW "$ADMIN_PW"
  cat > "$APP_DIR/compose.yaml" <<EOF
services:
  meilisearch:
    image: $IMAGE
    container_name: meilisearch
    restart: unless-stopped
    environment:
      MEILI_ENV: production
      MEILI_MASTER_KEY: \${ADMIN_PW}
      MEILI_NO_ANALYTICS: "true"
    volumes:
      - ./meili_data:/meili_data
    ports:
      - "127.0.0.1:$APP_PORT:7700"
EOF
}

# Không có tài khoản để tạo: kiểm khoá master bằng GET /keys (khoá qua stdin của curl).
app_setup() {
  api GET /keys -K - <<<"header = \"Authorization: Bearer $ADMIN_PW\"" | jq -e '.results | type == "array"' >/dev/null
}
