#!/usr/bin/env bash
# Cài Jenkins — script 1-Click của Tino, không dùng model.
# TỆP SINH TỰ ĐỘNG bởi tools/gen_catalog.py = lib/install.sh (phần chung) + catalog/jenkins/app.sh (phần riêng).
# Sửa ở hai tệp đó rồi chạy lại gen_catalog.py; bản chép của module: apps/jenkins/install.sh (trùng từng byte).
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

# --- phần riêng: catalog/jenkins/app.sh ---
# shellcheck disable=SC2034  # metadata của danh mục; không phải ứng dụng nào cũng dùng hết
{
  APP_SLUG='jenkins'
  APP_TITLE='Jenkins'
  APP_REPO='jenkinsci/jenkins'
  APP_REF='ea3f958268fe87ed86a5d1c2d90c5a99426b97ce'
  APP_PORT='8080'
  APP_HEALTH='/login'
  MIN_CPU='1'
  MIN_RAM_MB='2048'
  MIN_DISK_GB='20'
}
APP_VERSION=2.580.2
IMAGE='jenkins/jenkins:2.580.2-lts-jdk21@sha256:74401de6a6f92e1afe1b02d1c8e3d0c33f263bfb5275dd8813f9150355f2367b'
WAIT_SECS=900  # Java khởi động chậm trên VPS nhỏ
APP_NOTE='Jenkins chưa cài plugin nào (bỏ qua trình hướng dẫn): vào Manage Jenkins → Plugins để cài Pipeline, Git… Đăng ký tự do đang tắt.'
# Người chưa đăng nhập vào / bị Jenkins trả 403 (kèm trang tự chuyển tới /login): chuyển thẳng tới /login để kiểm HTTPS thấy 3xx.
CADDY_EXTRA=$'\t@anon {\n\t\tpath /\n\t\tnot header Cookie *JSESSIONID*\n\t}\n\tredir @anon /login 302\n'

app_files() {
  # mật khẩu quản trị qua tệp (không để trong biến môi trường mà job chạy trên máy chủ Jenkins đọc được bằng env)
  ( umask 077; printf '%s' "$ADMIN_PW" > "$APP_DIR/admin_password" )
  chown 1000:1000 "$APP_DIR/admin_password"  # user jenkins của image
  cat > "$APP_DIR/tino-admin.groovy" <<'EOF'
// Chạy mỗi lần Jenkins khởi động (thay trình hướng dẫn cài đặt). Chỉ làm khi chưa bật bảo mật: tạo quản trị, tắt tự đăng ký,
// chỉ người đã đăng nhập mới làm được gì (không cho người lạ đọc), đặt Jenkins URL. Đã có thì không đổi gì.
import hudson.security.FullControlOnceLoggedInAuthorizationStrategy
import hudson.security.HudsonPrivateSecurityRealm
import hudson.security.SecurityRealm
import jenkins.model.Jenkins
import jenkins.model.JenkinsLocationConfiguration

def j = Jenkins.get()
if (j.securityRealm == SecurityRealm.NO_AUTHENTICATION) {
  def realm = new HudsonPrivateSecurityRealm(false)
  realm.createAccount(System.getenv('TINO_ADMIN_USER'), new File('/run/secrets/tino_admin_password').text.trim())
  j.securityRealm = realm
  def strategy = new FullControlOnceLoggedInAuthorizationStrategy()
  strategy.allowAnonymousRead = false
  j.authorizationStrategy = strategy
  def loc = JenkinsLocationConfiguration.get()
  loc.url = System.getenv('TINO_URL')
  loc.save()
  j.save()
}
EOF
  cat > "$APP_DIR/compose.yaml" <<EOF
services:
  jenkins:
    image: $IMAGE
    restart: unless-stopped
    environment:
      JAVA_OPTS: -Djenkins.install.runSetupWizard=false
      TINO_ADMIN_USER: $ADMIN_USER
      TINO_URL: $TINO_URL
    volumes:
      - jenkins_home:/var/jenkins_home
      - ./tino-admin.groovy:/var/jenkins_home/init.groovy.d/tino-admin.groovy:ro
      - ./admin_password:/run/secrets/tino_admin_password:ro
    ports:
      - "127.0.0.1:$APP_PORT:8080"
volumes:
  jenkins_home:
EOF
}

app_setup() {
  [ "$(curl -s -o /dev/null -w '%{http_code}' "http://127.0.0.1:$APP_PORT/api/json")" = 403 ] ||
    die 'Jenkins vẫn cho người chưa đăng nhập truy cập.'
  # đăng nhập thử bằng Basic auth (mật khẩu qua stdin của curl)
  api GET /whoAmI/api/json -K - <<<"user = \"$ADMIN_USER:$ADMIN_PW\"" |
    jq -e --arg u "$ADMIN_USER" '.authenticated == true and .name == $u' >/dev/null
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
