APP_VERSION=0.97.0
IMAGE='docmost/docmost:0.97.0@sha256:40c454d74ffdd9ecb15833e4d96f3a630d59aad862a1869381ae6ee086454419'
DB_IMAGE='postgres:18.7-alpine@sha256:b6972e1115a4ff8eba5d7f7d19184926d1e16d7d1136ae1e1a7ebf286da0f015'
REDIS_IMAGE='redis:8.10.3-alpine@sha256:7958cfbb9d152f87dadfbc89f1b0b15938f0b81ff8982feb327476f4911935c3'
ADMIN_USER="admin@$TINO_HOST"  # Docmost đăng nhập bằng email
APP_NOTE='Đăng nhập bằng email quản trị; mời thành viên ở Settings → Members (gửi lời mời qua email cần cấu hình SMTP, hoặc sao chép liên kết mời).'

app_files() {
  secret DB_PASSWORD
  secret APP_SECRET 64
  cat > "$APP_DIR/compose.yaml" <<EOF
services:
  db:
    image: $DB_IMAGE
    restart: unless-stopped
    environment:
      POSTGRES_DB: docmost
      POSTGRES_USER: docmost
      POSTGRES_PASSWORD: \${DB_PASSWORD}
    volumes:
      - ./db:/var/lib/postgresql
    healthcheck:
      test: ["CMD", "pg_isready", "-h", "127.0.0.1", "-U", "docmost", "-d", "docmost"]
      interval: 5s
      retries: 60
  redis:
    image: $REDIS_IMAGE
    restart: unless-stopped
    command: ["redis-server", "--appendonly", "yes", "--maxmemory-policy", "noeviction"]
    volumes:
      - ./redis:/data
  docmost:
    image: $IMAGE
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
      redis:
        condition: service_started
    environment:
      APP_URL: ${TINO_URL%/}
      APP_SECRET: \${APP_SECRET}
      DATABASE_URL: postgresql://docmost:\${DB_PASSWORD}@db:5432/docmost
      REDIS_URL: redis://redis:6379
    volumes:
      - storage:/app/data/storage
    ports:
      - "127.0.0.1:$APP_PORT:3000"
volumes:
  storage:
EOF
}

dm_login() {
  jq -n --arg e "$ADMIN_USER" --arg p "$ADMIN_PW" '{email: $e, password: $p}' |
    api POST /api/auth/login -H 'Content-Type: application/json' -d @- >/dev/null
}

# Docmost chưa có workspace thì POST /api/auth/setup tạo workspace + chủ sở hữu (SetupGuard chỉ cho khi chưa có workspace).
app_setup() {
  dm_login 2>/dev/null && return 0
  jq -n --arg e "$ADMIN_USER" --arg p "$ADMIN_PW" '{name: "Admin", email: $e, password: $p, workspaceName: "Docmost"}' |
    api POST /api/auth/setup -H 'Content-Type: application/json' -d @- >/dev/null ||
    refuse 'Docmost trên VPS đã có workspace từ trước, không tạo được tài khoản quản trị mới.'
  dm_login
}
