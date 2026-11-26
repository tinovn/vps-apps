APP_VERSION=3.4.1
SERVER_IMAGE='ghcr.io/immich-app/immich-server:v3.4.1@sha256:7c489add298fc2f92cda4c777de6462aa206877e04087b815f62c7664af0b53b'
ML_IMAGE='ghcr.io/immich-app/immich-machine-learning:v3.4.1@sha256:8adebf414256f6e4f837bfbb66fa94f14f4da7260e3a1d65cbba49e4e35d8764'
# redis và postgres: đúng image + digest trong docker-compose.yml chính thức của v3.4.1
REDIS_IMAGE='docker.io/valkey/valkey:9@sha256:418652cfb58ef879d4978c33553735d7147016032d5aefaa14c828e611eb9dfd'
DB_IMAGE='ghcr.io/immich-app/postgres:14-vectorchord0.4.3-pgvectors0.2.0@sha256:bcf63357191b76a916ae5eb93464d65c07511da41e3bf7a8416db519b40b1c23'
ADMIN_USER="admin@$TINO_HOST"  # Immich đăng nhập bằng email
WAIT_SECS=600
APP_NOTE='Cài ứng dụng Immich trên điện thoại, nhập địa chỉ máy chủ là URL ở trên để sao lưu ảnh; ảnh nằm ở /opt/immich/library trên VPS.'

app_files() {
  # từ v3, container machine-learning trên amd64 cần CPU x86-64-v2 (SSE4.2, POPCNT)
  if ! grep -qw sse4_2 /proc/cpuinfo || ! grep -qw popcnt /proc/cpuinfo; then
    refuse 'Immich 3 cần CPU hỗ trợ x86-64-v2 (SSE4.2, POPCNT); hãy đổi loại CPU của VPS (vd. host hoặc x86-64-v2-AES).'
  fi
  secret DB_PASSWORD
  # theo docker-compose.yml + example.env của bản v3.4.1, chỉ đổi: cổng 127.0.0.1, biến môi trường viết thẳng thay env_file
  cat > "$APP_DIR/compose.yaml" <<EOF
services:
  immich-server:
    image: $SERVER_IMAGE
    restart: unless-stopped
    environment:
      DB_PASSWORD: \${DB_PASSWORD}
      DB_USERNAME: postgres
      DB_DATABASE_NAME: immich
    volumes:
      - ./library:/data
      - /etc/localtime:/etc/localtime:ro
    ports:
      - "127.0.0.1:$APP_PORT:2283"
    depends_on:
      - redis
      - database
  immich-machine-learning:
    image: $ML_IMAGE
    restart: unless-stopped
    environment:
      MACHINE_LEARNING_MODEL_REVISION: v2
    volumes:
      - model-cache:/cache
  redis:
    image: $REDIS_IMAGE
    restart: unless-stopped
    healthcheck:
      test: redis-cli ping | grep -q PONG || exit 1
  database:
    image: $DB_IMAGE
    restart: unless-stopped
    environment:
      POSTGRES_PASSWORD: \${DB_PASSWORD}
      POSTGRES_USER: postgres
      POSTGRES_DB: immich
      POSTGRES_INITDB_ARGS: "--data-checksums"
    volumes:
      - ./postgres:/var/lib/postgresql/data
    shm_size: 128mb
volumes:
  model-cache:
EOF
}

# Admin đầu tiên: POST /api/auth/admin-sign-up khi /api/server/config báo chưa khởi tạo; rồi đăng nhập thử.
app_setup() {
  local cred
  cred=$(jq -n --arg e "$ADMIN_USER" --arg p "$ADMIN_PW" '{email: $e, password: $p}')
  if api GET /api/server/config | jq -e '.isInitialized == false' >/dev/null; then
    jq -c '. + {name: "Admin"}' <<<"$cred" |
      api POST /api/auth/admin-sign-up -H 'Content-Type: application/json' --data-binary @- >/dev/null
  fi
  api POST /api/auth/login -H 'Content-Type: application/json' --data-binary @- <<<"$cred" | jq -e '.isAdmin == true' >/dev/null
}
