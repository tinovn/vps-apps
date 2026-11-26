#!/usr/bin/env bash
# Cài MaxKB — script 1-Click của Tino, không dùng model.
# TỆP SINH TỰ ĐỘNG bởi tools/gen_catalog.py = lib/install.sh (phần chung) + catalog/maxkb/app.sh (phần riêng).
# Sửa ở hai tệp đó rồi chạy lại gen_catalog.py; bản chép của module: apps/maxkb/install.sh (trùng từng byte).
#
# HostBill (module tino_vps_apps, VpsAppRunner) ghi tệp này vào /root/.tino-app/<job>/ qua QEMU guest agent và chạy bằng
# systemd-run với TINO_HOST, TINO_URL, TINO_DIR trong môi trường. Giao ước:
#   - dòng "##STEP <câu>"  → tiến độ cho khách; "##NOTE <câu>" → ghi chú khi xong; "##ERROR <câu>" → lý do khi dừng
#   - thoát 0 = đã cài (HostBill vẫn tự kiểm); 3 = VPS không đáp ứng (precheck_failed); mã khác = lỗi (install_failed)
#   - chạy lại nhiều lần được: giữ mật khẩu và bí mật cũ, bước đã xong thì không đổi gì
#   - không bao giờ in mật khẩu; ứng dụng chỉ nghe 127.0.0.1, ra ngoài qua Caddy (HTTPS) sau khi đã có tài khoản quản trị
#
# Phần riêng (app.sh) đặt APP_VERSION, viết app_files (tạo $APP_DIR/compose.yaml và tệp cấu hình), tuỳ chọn app_setup
# (tạo / kiểm tài khoản quản trị qua 127.0.0.1, trước khi mở HTTPS). Biến đổi được: ADMIN_USER, APP_AUTH, WAIT_SECS,
# APP_APT, CADDY_EXTRA, APP_NOTE, LOGIN_NOTE. Hàm dùng được: secret, envset, envget, compose, api, wait_http, step, note, refuse, die.
set -euo pipefail
set -E  # trap ERR có hiệu lực cả trong hàm
trap 'exit 1' ERR  # lệnh nào lỗi cũng thoát 1: mã 3 chỉ do refuse (VPS không đáp ứng)
export DEBIAN_FRONTEND=noninteractive
: "${TINO_HOST:?}" "${TINO_URL:?}"

CREDS=/root/tino-app.txt
APT=(apt-get -o DPkg::Lock::Timeout=600 -q)
ADMIN_USER='admin' # tên đăng nhập quản trị (app.sh đổi được, vd. email)
APP_AUTH=app       # app: ứng dụng tự có đăng nhập; basic: ứng dụng không có đăng nhập, Caddy hỏi tài khoản
WAIT_SECS=300      # chờ ứng dụng trả 2xx/3xx ở healthcheck
APP_APT=()         # gói Ubuntu thêm
CADDY_EXTRA=''     # chỉ thị Caddy thêm trong khối site
APP_NOTE=''        # ghi chú riêng cho khách khi xong
LOGIN_NOTE=''      # câu đăng nhập riêng (vd. ứng dụng chỉ có mật khẩu / khoá API); trống = tài khoản ADMIN_USER + mật khẩu trong CREDS

step() { echo "##STEP $*"; }
note() { echo "##NOTE $*"; }
refuse() { echo "##ERROR $*"; exit 3; }
die() { echo "##ERROR $*"; exit 1; }
# chuỗi ngẫu nhiên [A-Za-z0-9] (không dùng "tr </dev/urandom | head": tr chết SIGPIPE, pipefail làm script thoát)
rand() { local s; s=$(head -c 1024 /dev/urandom | base64 -w0 | tr -dc A-Za-z0-9); printf '%s' "${s:0:${1:-32}}"; }

# $APP_DIR/.env (600): compose đọc biến từ đây. envset NAME VALUE ghi/đổi một dòng; secret NAME [độ dài] tạo một lần.
envset() {
  (
    umask 077
    touch "$APP_DIR/.env"
    grep -v "^$1=" "$APP_DIR/.env" > "$APP_DIR/.env.tmp" || true
    printf '%s=%s\n' "$1" "$2" >> "$APP_DIR/.env.tmp"
    mv "$APP_DIR/.env.tmp" "$APP_DIR/.env"
  )
}
secret() { grep -q "^$1=." "$APP_DIR/.env" 2>/dev/null || envset "$1" "$(rand "${2:-32}")"; }
envget() { sed -n "s/^$1=//p" "$APP_DIR/.env"; }
compose() { docker compose --project-directory "$APP_DIR" -f "$APP_DIR/compose.yaml" "$@"; }

# api PHƯƠNG_THỨC ĐƯỜNG_DẪN [tham số curl…]: gọi ứng dụng qua 127.0.0.1:APP_PORT, in thân; HTTP ≥ 400 → lỗi (mã + đầu thân ra stderr)
api() {
  local m=$1 p=$2 out code
  shift 2
  out=$(curl -sS -X "$m" -w '\n%{http_code}' "$@" "http://127.0.0.1:$APP_PORT$p") || return 1
  code=${out##*$'\n'}
  out=${out%$'\n'*}
  if [ "$code" -ge 400 ]; then echo "api $m $p → HTTP $code: ${out:0:300}" >&2; return 1; fi
  printf '%s' "$out"
}

# wait_http ĐƯỜNG_DẪN GIÂY: chờ 127.0.0.1:APP_PORT trả 2xx/3xx
wait_http() {
  local end=$((SECONDS + $2))
  while [ "$SECONDS" -lt "$end" ]; do
    case "$(curl -s -o /dev/null -m 10 -w '%{http_code}' "http://127.0.0.1:$APP_PORT$1" || true)" in 2* | 3*) return 0 ;; esac
    sleep 3
  done
  return 1
}

# --- phần riêng: catalog/maxkb/app.sh ---
# shellcheck disable=SC2034  # metadata của danh mục; không phải ứng dụng nào cũng dùng hết
{
  APP_SLUG='maxkb'
  APP_TITLE='MaxKB'
  APP_REPO='1Panel-dev/MaxKB'
  APP_REF='792a525c5a78e42bf04b91c251f747a0bc3e8517'
  APP_PORT='8080'
  APP_HEALTH='/admin/'
  MIN_CPU='2'
  MIN_RAM_MB='2048'
  MIN_DISK_GB='20'
}
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
# --- hết phần riêng ---

APP_DIR=/opt/$APP_SLUG

https_ok() {
  for _ in $(seq 1 "$1"); do
    case "$(curl -sk -o /dev/null -m 10 -w '%{http_code}' --resolve "$TINO_HOST:443:127.0.0.1" "https://$TINO_HOST/" || true)" in
      2* | 3* | 401) return 0 ;;
    esac
    sleep 5
  done
  return 1
}

caddy_site() {
  local auth='' hash
  if [ "$APP_AUTH" = basic ]; then
    hash=$(caddy hash-password --plaintext "$ADMIN_PW")
    auth=$(printf '\tbasicauth {\n\t\t%s %s\n\t}\n' "$ADMIN_USER" "$hash")
  fi
  printf '%s {\n%s%s\n\treverse_proxy 127.0.0.1:%s\n%s}\n' "$TINO_HOST" "$1" "$auth" "$APP_PORT" "$CADDY_EXTRA" > /etc/caddy/Caddyfile
  caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile >/dev/null
  systemctl enable caddy >/dev/null 2>&1
  systemctl reload-or-restart caddy
}

main() {
  step 'Kiểm tra cấu hình máy chủ'
  local os ram disk
  os=$(. /etc/os-release && echo "$ID $VERSION_ID|$PRETTY_NAME")
  case "${os%%|*}" in
    'ubuntu 24.04' | 'ubuntu 26.04') ;;
    *) refuse "$APP_TITLE cần Ubuntu 24.04 hoặc 26.04, VPS đang chạy ${os#*|}." ;;
  esac
  ram=$(free -m | awk '/^Mem:/{print $2}')
  disk=$(df -BG --output=avail / | tail -1 | tr -dc 0-9)
  [ "$(nproc)" -ge "$MIN_CPU" ] || refuse "$APP_TITLE cần ít nhất $MIN_CPU CPU, VPS có $(nproc)."
  [ "$ram" -ge $((MIN_RAM_MB * 85 / 100)) ] || refuse "$APP_TITLE cần khoảng $MIN_RAM_MB MB RAM, VPS có $ram MB."
  [ "$disk" -ge $((MIN_DISK_GB / 2)) ] || refuse "$APP_TITLE cần trống ít nhất $((MIN_DISK_GB / 2)) GB ổ đĩa, VPS còn $disk GB."

  step 'Chờ VPS khởi tạo xong'
  # VPS vừa tạo: cloud-init còn dist-upgrade, giữ khoá dpkg (OTE 17/11)
  if command -v cloud-init >/dev/null; then cloud-init status --wait >/dev/null 2>&1 || true; fi

  step 'Cài Docker và Caddy'
  "${APT[@]}" update
  "${APT[@]}" install -y docker.io docker-compose-v2 caddy curl jq "${APP_APT[@]}"
  # Docker Hub giới hạn lượt tải ẩn danh theo IP: tải qua mirror.gcr.io (bản cache của Google), không có thì Docker tự về Docker Hub.
  # Image đều ghim digest nên nội dung không phụ thuộc nơi tải. Không đụng daemon.json đã có.
  if [ ! -s /etc/docker/daemon.json ]; then
    install -d -m 755 /etc/docker
    printf '{\n  "registry-mirrors": ["https://mirror.gcr.io"]\n}\n' > /etc/docker/daemon.json
    systemctl restart docker
  fi
  systemctl enable --now docker

  # Mật khẩu quản trị sinh và nằm trên VPS (600), trước khi mở HTTPS; chạy lại thì giữ tài khoản cũ.
  (
    umask 077
    if ! grep -q '^password=.' "$CREDS" 2>/dev/null; then
      printf 'url=%s\nuser=%s\npassword=%s-Tk9\n' "$TINO_URL" "$ADMIN_USER" "$(rand 20)" > "$CREDS"
    fi
  )
  sed -i "s#^url=.*#url=$TINO_URL#" "$CREDS"
  chmod 600 "$CREDS"
  ADMIN_USER=$(sed -n 's/^user=//p' "$CREDS")
  ADMIN_PW=$(sed -n 's/^password=//p' "$CREDS")

  step "Tải $APP_TITLE"
  install -d -m 755 "$APP_DIR"
  app_files
  compose pull -q
  compose up -d

  step 'Chờ ứng dụng khởi động'
  if ! wait_http "$APP_HEALTH" "$WAIT_SECS"; then
    compose logs --tail 40 2>&1 | tail -c 6000
    die "$APP_TITLE không trả lời sau $((WAIT_SECS / 60)) phút."
  fi

  step 'Tạo tài khoản quản trị'
  if declare -F app_setup >/dev/null; then app_setup; fi

  step 'Mở HTTPS qua Caddy'
  caddy_site ''
  if ufw status 2>/dev/null | grep -q 'Status: active'; then ufw allow 80/tcp >/dev/null; ufw allow 443/tcp >/dev/null; fi
  if ! https_ok 24; then
    # Let's Encrypt không cấp được trong 2 phút: chứng chỉ nội bộ, ghi chú cho khách
    caddy_site $'\ttls internal\n'
    https_ok 12 || { journalctl -u caddy -n 30 --no-pager; exit 1; }
    note 'Trình duyệt sẽ cảnh báo chứng chỉ cho tới khi tên miền được trỏ về VPS.'
  fi

  step 'Kiểm tra lần cuối'
  local exposed
  exposed=$(docker ps --format '{{.Names}} {{.Ports}}' | grep -E '(0\.0\.0\.0|\[::\]|:::):[0-9]' || true)
  exposed+=$(ss -ltnH "sport = :$APP_PORT" | awk '$4 !~ /^(127\.0\.0\.1|\[::1\]):/ {print " " $4}')
  [ -z "$exposed" ] || die "Cổng ứng dụng đang mở ra ngoài localhost:$exposed"
  [ -z "$APP_NOTE" ] || note "$APP_NOTE"
  if [ -n "$LOGIN_NOTE" ]; then
    note "$APP_TITLE $APP_VERSION đã chạy tại $TINO_URL. $LOGIN_NOTE"
  elif [ "$APP_AUTH" = basic ]; then
    note "$APP_TITLE $APP_VERSION đã chạy tại $TINO_URL. Trình duyệt sẽ hỏi tài khoản: $ADMIN_USER, mật khẩu nằm trong $CREDS trên VPS."
  else
    note "$APP_TITLE $APP_VERSION đã chạy tại $TINO_URL. Đăng nhập bằng tài khoản $ADMIN_USER, mật khẩu nằm trong $CREDS trên VPS."
  fi
}

main
