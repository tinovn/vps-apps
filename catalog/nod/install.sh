#!/usr/bin/env bash
# Cài Nod — script 1-Click của Tino, không dùng model.
# TỆP SINH TỰ ĐỘNG bởi tools/gen_catalog.py = lib/install.sh (phần chung) + catalog/nod/app.sh (phần riêng).
# Sửa ở hai tệp đó rồi chạy lại gen_catalog.py; bản chép của module: apps/nod/install.sh (trùng từng byte).
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

# --- phần riêng: catalog/nod/app.sh ---
# shellcheck disable=SC2034  # metadata của danh mục; không phải ứng dụng nào cũng dùng hết
{
  APP_SLUG='nod'
  APP_TITLE='Nod'
  APP_REPO='n8n-io/nod'
  APP_REF='1128fcfd770d619f3391e0bd9f1ca2f9966f2be6'
  APP_PORT='4310'
  APP_HEALTH='/'
  MIN_CPU='2'
  MIN_RAM_MB='8192'
  MIN_DISK_GB='50'
}
APP_VERSION=0.9.7
# images/nod/build.sh nod-v0.9.7 → ghcr.io/tinovn; postgres, node ghim như compose.yaml của tag
IMG_SERVER='ghcr.io/tinovn/nod-server:0.9.7@sha256:f9d5c09352934e90666c67bcefcf15cdab2f86d65204f2a642b7b36936f26f21'
IMG_BROWSER='ghcr.io/tinovn/nod-browser:0.9.7@sha256:c7cae1a2d407c3bff2b9e7d9ee07252841fe4f2bc1a5dcd7a5c0c83227894bca'
IMG_WORKSPACE='ghcr.io/tinovn/nod-workspace:0.9.7@sha256:5694ba3f6fdce69e863eca3d64c0d1e59e44dac1cfe597f48b93e8568d05a036'
IMG_POSTGRES='postgres:17-alpine@sha256:eee6c6e1b0894fa4fe0075eb054af9fd1cf39a35321c2d4110626cfe506411fb'
IMG_NODE='node:24.21.0-bookworm-slim@sha256:d6aa754f16b3197301076f047b5def2f02ea1dbbc2ca920407d46d7ec7f87b20'
PROXY_SHA256='cb2be82c47e373fde31d2091a0d1acc1e2b57cf27d1ebdb3594820df87fffc41'  # deployment/self-host/docker-proxy.mjs
WAIT_SECS=600
APP_NOTE='Kết nối model trong Nod (đăng nhập ChatGPT Plus/Pro hoặc nhập khoá API), rồi nối Gmail, Slack… ở mục Apps. Dùng app Nod trên máy tính: chọn Connect to a server, nhập địa chỉ trên và access token.'
LOGIN_NOTE='Nod không có tên đăng nhập: nhập access token, là mật khẩu trong /root/tino-app.txt trên VPS.'

app_files() {
  envset COMPOSE_PROJECT_NAME nod  # tên container nod-workspace-nod, nod-browser-nod (docker-proxy chỉ cho 2 tên này)
  secret NOD_AUTH_TOKEN 64
  secret NOD_POSTGRES_PASSWORD 64
  grep -q '^NOD_VAULT_KEY=.' "$APP_DIR/.env" || envset NOD_VAULT_KEY "$(openssl rand -base64 32)"
  envset NOD_PUBLIC_URL "https://$TINO_HOST"
  envset NOD_ANALYTICS_ENABLED false
  # khách đăng nhập bằng token: ghi đè mật khẩu khung đã sinh (chạy lại vẫn là token cũ)
  sed -i "s#^password=.*#password=$(envget NOD_AUTH_TOKEN)#" "$CREDS"

  local proxy="$APP_DIR/docker-proxy.mjs"
  if ! echo "$PROXY_SHA256  $proxy" | sha256sum -c --status 2>/dev/null; then
    curl -fsSL --retry 3 --retry-all-errors -m 60 "https://raw.githubusercontent.com/n8n-io/nod/$APP_REF/deployment/self-host/docker-proxy.mjs" \
      -o "$proxy.tmp" || die 'Không tải được docker-proxy.mjs của Nod từ GitHub.'
    echo "$PROXY_SHA256  $proxy.tmp" | sha256sum -c --status || die 'docker-proxy.mjs tải về sai sha256.'
    mv "$proxy.tmp" "$proxy"
  fi
  chmod 644 "$proxy"

  cat > "$APP_DIR/compose.yaml" <<YAML
services:
  server:
    image: $IMG_SERVER
    restart: unless-stopped
    init: true
    env_file: .env
    environment:
      NODE_ENV: production
      NOD_ENVIRONMENT: production
      NOD_HOST: 0.0.0.0
      PORT: 4310
      NOD_DATA_ROOT: /var/lib/nod
      DATABASE_URL: postgresql://nod:\${NOD_POSTGRES_PASSWORD}@postgres:5432/nod
      DOCKER_HOST: tcp://runtime:2375
      WORKSPACE_CONTAINER: nod-workspace-nod
      BROWSER_CONTAINER: nod-browser-nod
    ports:
      - "127.0.0.1:$APP_PORT:4310"
    volumes:
      - server-data:/var/lib/nod
      - workspace-data:/var/lib/nod/workspaces
    tmpfs:
      - /tmp:uid=1000,gid=1000,mode=1777,size=256m
    read_only: true
    cap_drop: [ALL]
    security_opt: [no-new-privileges:true]
    pids_limit: 512
    mem_limit: 2g
    networks: [backend, control, outbound]
    depends_on:
      postgres:
        condition: service_healthy
      runtime:
        condition: service_started
      browser:
        condition: service_healthy
      workspace:
        condition: service_started
    healthcheck:
      test: ['CMD', 'node', '/app/healthcheck.mjs']
      interval: 15s
      timeout: 6s
      retries: 10
      start_period: 60s

  postgres:
    image: $IMG_POSTGRES
    restart: unless-stopped
    environment:
      POSTGRES_USER: nod
      POSTGRES_PASSWORD: \${NOD_POSTGRES_PASSWORD}
      POSTGRES_DB: nod
    volumes:
      - postgres-data:/var/lib/postgresql/data
    networks: [backend]
    healthcheck:
      test: ['CMD-SHELL', 'pg_isready -U nod -d nod']
      interval: 5s
      timeout: 3s
      retries: 30

  runtime:
    image: $IMG_NODE
    restart: unless-stopped
    init: true
    command: ['node', '/app/docker-proxy.mjs']
    environment:
      WORKSPACE_CONTAINER: nod-workspace-nod
      BROWSER_CONTAINER: nod-browser-nod
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
      - ./docker-proxy.mjs:/app/docker-proxy.mjs:ro
    networks: [control]
    read_only: true
    cap_drop: [ALL]
    security_opt: [no-new-privileges:true]
    pids_limit: 64
    mem_limit: 128m

  browser:
    image: $IMG_BROWSER
    container_name: nod-browser-nod
    hostname: nod-browser
    restart: unless-stopped
    init: true
    cap_drop: [ALL]
    security_opt: [no-new-privileges:true]
    read_only: true
    pids_limit: 1024
    mem_limit: 3g
    shm_size: 512m
    volumes:
      - browser-data:/data
    tmpfs:
      - /tmp:size=512m
      - /home/node:uid=1000,gid=1000,mode=700,size=256m
    networks: [browser]
    healthcheck:
      test: ['CMD', 'node', '-e', 'const s=require("node:net").connect("/data/control.sock");s.on("connect",()=>{s.end();process.exit(0)});s.on("error",()=>process.exit(1))']
      interval: 5s
      timeout: 3s
      retries: 30

  workspace:
    image: $IMG_WORKSPACE
    container_name: nod-workspace-nod
    restart: unless-stopped
    init: true
    cap_drop: [ALL]
    security_opt: [no-new-privileges:true]
    pids_limit: 512
    mem_limit: 2g
    volumes:
      - workspace-data:/workspace
      - workspace-tools:/home/node
    network_mode: service:workspace-network
    depends_on:
      workspace-network:
        condition: service_healthy
        restart: true
    command: ['sleep', 'infinity']

  workspace-network:
    image: $IMG_WORKSPACE
    dns: [1.1.1.1, 8.8.8.8]
    user: root
    restart: unless-stopped
    init: true
    entrypoint: /usr/local/bin/nod-workspace-network
    cap_drop: [ALL]
    cap_add: [NET_ADMIN]
    security_opt: [no-new-privileges:true]
    read_only: true
    tmpfs:
      - /tmp:size=1m
    pids_limit: 32
    mem_limit: 64m
    networks: [workspace]
    healthcheck:
      test: ['CMD', 'test', '-f', '/tmp/network-ready']
      interval: 2s
      timeout: 3s
      retries: 10

networks:
  backend:
    internal: true
  control:
    internal: true
  outbound:
  browser:
  workspace:

volumes:
  server-data:
  postgres-data:
  workspace-data:
  workspace-tools:
  browser-data:
YAML
}

# Server chỉ nhận Host trùng NOD_PUBLIC_URL (127.0.0.1 → 403) và /api/* cần token: chờ /api/health như healthcheck.mjs của
# Nod (kiểm cả PostgreSQL), bỏ qua đường APP_HEALTH ("/", dành cho bước tự kiểm của HostBill). Định nghĩa lại wait_http của
# khung; token đi qua stdin (-K -), không lộ trên dòng lệnh.
wait_http() {
  local end=$((SECONDS + $2))
  while [ "$SECONDS" -lt "$end" ]; do
    case "$(curl -s -o /dev/null -m 10 -w '%{http_code}' -H "Host: $TINO_HOST" -K - "http://127.0.0.1:$APP_PORT/api/health" \
      <<<"header = \"Authorization: Bearer $(envget NOD_AUTH_TOKEN)\"" || true)" in 2*) return 0 ;; esac
    sleep 3
  done
  return 1
}

# Không có tài khoản để tạo: kiểm token đang bắt buộc (không token → 401, Host lạ → 403) trước khi mở HTTPS.
app_setup() {
  local code
  code=$(curl -s -o /dev/null -m 10 -w '%{http_code}' -H "Host: $TINO_HOST" "http://127.0.0.1:$APP_PORT/api/health" || true)
  [ "$code" = 401 ] || die "Nod trả HTTP $code cho /api/health khi không có token (cần 401)."
  code=$(curl -s -o /dev/null -m 10 -w '%{http_code}' "http://127.0.0.1:$APP_PORT/" || true)
  [ "$code" = 403 ] || die "Nod trả HTTP $code cho Host 127.0.0.1 (cần 403)."
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
