APP_VERSION=2.10.8-lts
# all-in-one: PostgreSQL + Redis + MaxKB trong một container, dữ liệu ở /opt/maxkb
IMAGE='1panel/maxkb:v2.10.8-lts@sha256:027fdb79e4ef9cd9579418e900ea94cf9521ee4ddc4dd0fc1b65af0245357d54'
WAIT_SECS=600  # lần đầu khởi tạo PostgreSQL và migrate
APP_NOTE='Trang quản trị ở /admin/; vào Mô hình (Model) thêm khoá API trước khi tạo ứng dụng và kho tri thức.'
MK_API=/admin/api
MK_DEFAULT_PW='MaxKB@123..'  # mật khẩu mặc định của image (README), đổi ngay trên 127.0.0.1

app_files() {
  # MaxKB nhận mật khẩu 6–20 ký tự có chữ thường, chữ hoa, số, ký tự đặc biệt; mật khẩu chung dài 24 → rút còn 20 (đuôi -Tk9 giữ đủ loại)
  if [ "${#ADMIN_PW}" -gt 20 ]; then
    ADMIN_PW="${ADMIN_PW:0:16}-Tk9"
    sed -i "s/^password=.*/password=$ADMIN_PW/" "$CREDS"
  fi
  cat > "$APP_DIR/compose.yaml" <<EOF
services:
  maxkb:
    image: $IMAGE
    container_name: maxkb
    restart: unless-stopped
    volumes:
      - ./data:/opt/maxkb
    ports:
      - "127.0.0.1:$APP_PORT:8080"
EOF
}

# mk_login MẬT_KHẨU: in token. Lỗi đăng nhập MaxKB trả HTTP 200 kèm code ≠ 200 trong thân.
mk_login() {
  jq -n --arg u "$ADMIN_USER" --arg p "$1" '{username: $u, password: $p}' \
    | api POST "$MK_API/user/login" -H 'Content-Type: application/json' --data-binary @- | jq -er 'select(.code == 200) | .data.token'
}

# Mỗi lần đăng nhập sai MaxKB bắt captcha cho lần sau, nên không "thử" mật khẩu: tệp đánh dấu cho biết đã đổi chưa.
app_setup() {
  local token reset="$MK_API/user/current/reset_password" mark="$APP_DIR/.admin-pw-set"
  if [ ! -f "$mark" ]; then
    token=$(mk_login "$MK_DEFAULT_PW") || die 'Không đăng nhập được MaxKB bằng tài khoản mặc định (có thể đã đổi mật khẩu từ trước).'
    # token đi qua tệp cấu hình curl (-K), mật khẩu mới qua stdin
    jq -n --arg p "$ADMIN_PW" '{password: $p, re_password: $p}' \
      | api POST "$reset" -K <(printf 'header = "Authorization: Bearer %s"\n' "$token") \
        -H 'Content-Type: application/json' --data-binary @- | jq -e '.code == 200' >/dev/null
    touch "$mark"
  fi
  mk_login "$ADMIN_PW" >/dev/null
}
