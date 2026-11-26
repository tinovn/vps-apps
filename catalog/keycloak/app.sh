APP_VERSION=26.8.2
IMAGE='quay.io/keycloak/keycloak:26.8.2@sha256:c68e286cacd87b942ac1939a0a1481461109d6acd3a57dc496969a319a76bbf0'
DB_IMAGE='postgres:17.12-alpine@sha256:a77aa70e641402a21411b92b721c58d10f23b50ae5fdd2333efd22d166e1e5f7'
WAIT_SECS=600
APP_NOTE='Trang quản trị ở /admin/ (realm master). Tạo realm riêng cho ứng dụng của bạn, không dùng realm master cho người dùng cuối.'

app_files() {
  secret DB_PASSWORD
  secret BOOT_PW 32
  # image đặt heap = 70% giới hạn RAM của container (+ ~300 MB ngoài heap); không giới hạn thì tính theo RAM cả VPS.
  # Cho Keycloak 2/3 RAM, phần còn lại cho PostgreSQL và hệ điều hành.
  local mem
  mem=$(($(free -m | awk '/^Mem:/{print $2}') * 2 / 3))
  cat > "$APP_DIR/compose.yaml" <<EOF
services:
  db:
    image: $DB_IMAGE
    restart: unless-stopped
    environment:
      POSTGRES_USER: keycloak
      POSTGRES_PASSWORD: \${DB_PASSWORD}
      POSTGRES_DB: keycloak
    volumes:
      - ./db:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U keycloak -d keycloak"]
      interval: 5s
      retries: 60
  keycloak:
    image: $IMAGE
    command: start
    restart: unless-stopped
    mem_limit: ${mem}m
    depends_on:
      db:
        condition: service_healthy
    environment:
      KC_DB: postgres
      KC_DB_URL_HOST: db
      KC_DB_URL_DATABASE: keycloak
      KC_DB_USERNAME: keycloak
      KC_DB_PASSWORD: \${DB_PASSWORD}
      KC_HOSTNAME: ${TINO_URL%/}
      KC_PROXY_HEADERS: xforwarded
      KC_HTTP_ENABLED: "true"
      # quản trị TẠM, chỉ tạo khi khởi tạo realm master; app_setup dùng nó tạo quản trị chính thức rồi xoá
      KC_BOOTSTRAP_ADMIN_USERNAME: tino-bootstrap
      KC_BOOTSTRAP_ADMIN_PASSWORD: \${BOOT_PW}
    ports:
      - "127.0.0.1:$APP_PORT:8080"
EOF
}

# kc_token TÊN MẬT_KHẨU: access token của client admin-cli (mật khẩu đi qua stdin của curl)
kc_token() {
  api POST /realms/master/protocol/openid-connect/token -d grant_type=password -d client_id=admin-cli \
    --data-urlencode "username=$1" -K - <<<"data-urlencode = \"password=$2\"" | jq -er .access_token
}

# kc PHƯƠNG_THỨC ĐƯỜNG_DẪN TOKEN [tham số curl…]: admin REST API của realm master
kc() {
  local m=$1 p=$2 t=$3
  shift 3
  api "$m" "/admin/realms/master$p" -H "Authorization: Bearer $t" -H 'Content-Type: application/json' "$@"
}

# Quản trị bootstrap của Keycloak bị đánh dấu "temporary" (giao diện nhắc tạo quản trị khác):
# tạo $ADMIN_USER chính thức với vai trò admin của realm master, đăng nhập thử, rồi xoá tino-bootstrap.
app_setup() {
  local tok uid
  if ! tok=$(kc_token "$ADMIN_USER" "$ADMIN_PW" 2>/dev/null); then
    tok=$(kc_token tino-bootstrap "$(envget BOOT_PW)")
    uid=$(kc GET "/users?exact=true&username=$ADMIN_USER" "$tok" | jq -r '.[0].id // empty')
    if [ -z "$uid" ]; then
      jq -n --arg u "$ADMIN_USER" --arg e "admin@$TINO_HOST" --arg p "$ADMIN_PW" \
        '{username: $u, email: $e, emailVerified: true, firstName: "Admin", lastName: "Tino", enabled: true,
          credentials: [{type: "password", value: $p, temporary: false}]}' |
        kc POST /users "$tok" --data-binary @- >/dev/null
      uid=$(kc GET "/users?exact=true&username=$ADMIN_USER" "$tok" | jq -er '.[0].id')
    fi
    kc GET /roles/admin "$tok" | jq -c '[.]' | kc POST "/users/$uid/role-mappings/realm" "$tok" --data-binary @- >/dev/null
    tok=$(kc_token "$ADMIN_USER" "$ADMIN_PW")
  fi
  uid=$(kc GET '/users?exact=true&username=tino-bootstrap' "$tok" | jq -r '.[0].id // empty')
  [ -z "$uid" ] || kc DELETE "/users/$uid" "$tok" >/dev/null
  # token của $ADMIN_USER đọc được admin API và tài khoản có vai trò admin
  kc GET /roles/admin/users "$tok" | jq -e --arg u "$ADMIN_USER" 'any(.[]; .username == $u)' >/dev/null
}
