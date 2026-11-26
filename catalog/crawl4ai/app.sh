APP_VERSION=0.9.5
IMAGE='unclecode/crawl4ai:0.9.5@sha256:0b05666882bfb67f45d559a5b827839c54127b74aedd723f8ab338a3571b5fc9'
WAIT_SECS=420
APP_NOTE='Thử ở /playground, theo dõi ở /dashboard. Trích xuất bằng LLM cần thêm khoá của nhà cung cấp mô hình.'
LOGIN_NOTE='Crawl4AI không có tài khoản: gọi API kèm header "Authorization: Bearer <mật khẩu>", mật khẩu nằm trong /root/tino-app.txt trên VPS.'

app_files() {
  envset ADMIN_PW "$ADMIN_PW"
  # Theo docker-compose.yml chính thức: rootfs chỉ đọc, bỏ mọi capability, tmpfs cho chỗ cần ghi (appuser = uid 999).
  # Có CRAWL4AI_API_TOKEN thì máy chủ bật cổng xác thực (Bearer) và mới nghe ngoài loopback của container.
  cat > "$APP_DIR/compose.yaml" <<EOF
services:
  crawl4ai:
    image: $IMAGE
    container_name: crawl4ai
    restart: unless-stopped
    environment:
      CRAWL4AI_API_TOKEN: \${ADMIN_PW}
      GUNICORN_BIND: "0.0.0.0:11235"  # mặc định [::]: hỏng nếu container tắt IPv6
    shm_size: 1gb
    user: appuser
    cap_drop:
      - ALL
    security_opt:
      - no-new-privileges:true
    read_only: true
    tmpfs:
      - /tmp
      - /var/lib/redis:uid=999,gid=999,mode=0700
      - /var/lib/crawl4ai/outputs:uid=999,gid=999,mode=0700
      - /home/appuser/.crawl4ai:uid=999,gid=999,mode=0700
      - /home/appuser/.cache/url_seeder:uid=999,gid=999,mode=0700
      - /home/appuser/.gunicorn:uid=999,gid=999,mode=0700
    pids_limit: 512
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:11235/health"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s
    ports:
      - "127.0.0.1:$APP_PORT:11235"
EOF
}

# Không có tài khoản: kiểm token (qua stdin của curl) và kiểm thiếu token thì bị từ chối.
app_setup() {
  api GET /schema -K - <<<"header = \"Authorization: Bearer $ADMIN_PW\"" | jq -e '.browser | type == "object"' >/dev/null
  [ "$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:$APP_PORT/schema")" = 401 ] || die 'Crawl4AI chưa bật xác thực.'
}
