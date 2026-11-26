APP_VERSION=2026.11.09
IMAGE='ghcr.io/huginn/huginn:v2026.11.09@sha256:9fd8da00f8df129dc2f2473b60e6f94498f91440a29dd8a2adc0131585983a8e'
DB_IMAGE='postgres:17.12-trixie@sha256:0d938e975177bef9f1f61f3f9dbcf2e0aa0a139568f66d3415ed8892eb97f6ac'
WAIT_SECS=600  # lần đầu: tạo bảng (rake db:migrate) và agent mẫu (db:seed) trước khi web chạy
APP_NOTE='Đăng ký tài khoản mới cần mã mời INVITATION_CODE trong /opt/huginn/.env.'

app_files() {
  secret DB_PASSWORD
  secret APP_SECRET_TOKEN 64
  secret INVITATION_CODE 24
  envset ADMIN_PW "$ADMIN_PW"
  cat > "$APP_DIR/compose.yaml" <<EOF
services:
  db:
    image: $DB_IMAGE
    restart: unless-stopped
    environment:
      POSTGRES_DB: huginn
      POSTGRES_USER: huginn
      POSTGRES_PASSWORD: \${DB_PASSWORD}
    volumes:
      - ./db:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U huginn -d huginn"]
      interval: 5s
      retries: 60
  # image multi-process: web + jobs (foreman); DB ngoài thì không chạy MySQL trong image
  huginn:
    image: $IMAGE
    container_name: huginn
    restart: unless-stopped
    depends_on:
      db:
        condition: service_healthy
    environment:
      DATABASE_ADAPTER: postgresql
      DATABASE_HOST: db
      DATABASE_PORT: "5432"
      DATABASE_NAME: huginn
      DATABASE_USERNAME: huginn
      DATABASE_PASSWORD: \${DB_PASSWORD}
      APP_SECRET_TOKEN: \${APP_SECRET_TOKEN}
      DOMAIN: $TINO_HOST
      FORCE_SSL: "true"
      INVITATION_CODE: \${INVITATION_CODE}
      TIMEZONE: Hanoi
      # db:seed chỉ tạo quản trị khi chưa có người dùng nào
      SEED_USERNAME: $ADMIN_USER
      SEED_EMAIL: admin@$TINO_HOST
      SEED_PASSWORD: \${ADMIN_PW}
    ports:
      - "127.0.0.1:$APP_PORT:3000"
EOF
}

# Đăng nhập thử qua form Devise như trình duyệt (FORCE_SSL: báo X-Forwarded-Proto https như Caddy;
# "localhost" để curl giữ cookie Secure qua http).
app_setup() {
  local jar page code url="http://localhost:$APP_PORT/users/sign_in"
  jar=$(mktemp)
  page=$(curl -sS -c "$jar" -H 'X-Forwarded-Proto: https' "$url")
  [[ $page =~ (name=\"authenticity_token\"\ value|name=\"csrf-token\"\ content)=\"([^\"]+)\" ]] ||
    { rm -f "$jar"; die 'Không đọc được trang đăng nhập Huginn.'; }
  code=$(curl -sS -o /dev/null -w '%{http_code} %{redirect_url}' -b "$jar" -H 'X-Forwarded-Proto: https' -K - "$url" <<EOF
data-urlencode = "authenticity_token=${BASH_REMATCH[2]}"
data-urlencode = "user[login]=$ADMIN_USER"
data-urlencode = "user[password]=$ADMIN_PW"
EOF
)
  rm -f "$jar"
  # đúng mật khẩu: 302/303 về trang chính; sai: 200/422 hiện lại form
  [[ $code == 30[23]\ * && $code != *sign_in* ]] || die "Huginn: đăng nhập thử bằng tài khoản quản trị không được (HTTP ${code%% *})."
}
