APP_VERSION=0.70.3
IMAGE='ghcr.io/dgtlmoon/changedetection.io:0.70.3@sha256:47b1e9cc3eff820e6022b655e3fcc948625f60c1770ae8b9c30aa3bf104dc255'
APP_APT=(python3)
APP_NOTE='Mật khẩu bị khoá theo SALTED_PASS trong /opt/changedetection/.env (không đổi trong Settings được). Bản cài không kèm trình duyệt Chrome: trang cần JavaScript có thể đọc thiếu.'
LOGIN_NOTE='Đăng nhập chỉ cần mật khẩu (không có tên đăng nhập), mật khẩu nằm trong /root/tino-app.txt trên VPS.'

app_files() {
  # Mật khẩu khoá qua biến SALTED_PASS = base64(salt 32 byte + pbkdf2_hmac sha256 100000 vòng), như User.check_password
  # trong changedetectionio/flask_app.py. Tính một lần, mật khẩu đọc từ stdin.
  if ! grep -q '^SALTED_PASS=.' "$APP_DIR/.env" 2>/dev/null; then
    local salted
    salted=$(python3 -c '
import base64, hashlib, os, sys
pw = sys.stdin.readline().rstrip("\n").encode()
salt = os.urandom(32)
print(base64.b64encode(salt + hashlib.pbkdf2_hmac("sha256", pw, salt, 100000)).decode())' <<<"$ADMIN_PW")
    envset SALTED_PASS "$salted"
  fi
  cat > "$APP_DIR/compose.yaml" <<EOF
services:
  changedetection:
    image: $IMAGE
    container_name: changedetection
    hostname: changedetection
    restart: unless-stopped
    environment:
      SALTED_PASS: \${SALTED_PASS}
      BASE_URL: ${TINO_URL%/}
      # sau Caddy: tin X-Forwarded-Proto/For/Host
      USE_X_SETTINGS: "1"
      DISABLE_VERSION_CHECK: "true"
    volumes:
      - ./datastore:/datastore
    ports:
      - "127.0.0.1:$APP_PORT:5000"
EOF
}

app_setup() {
  # đăng nhập thử như trình duyệt: lấy csrf_token ở /login, gửi mật khẩu (qua stdin của curl), rồi / phải trả 200 thay vì chuyển về /login
  local jar csrf code
  jar=$(mktemp)
  csrf=$(curl -sS -c "$jar" "http://127.0.0.1:$APP_PORT/login" | sed -n '/name="csrf_token"/{s/.*value="\([^"]*\)".*/\1/p;q}')
  [ -n "$csrf" ] || die 'Không đọc được csrf_token ở trang đăng nhập changedetection.io.'
  api POST /login -b "$jar" -c "$jar" --data-urlencode "csrf_token=$csrf" -K - <<<"data-urlencode = \"password=$ADMIN_PW\"" >/dev/null
  code=$(curl -s -o /dev/null -w '%{http_code}' -b "$jar" "http://127.0.0.1:$APP_PORT/")
  rm -f "$jar"
  [ "$code" = 200 ] || die "Đăng nhập thử changedetection.io không được (HTTP $code)."
}
