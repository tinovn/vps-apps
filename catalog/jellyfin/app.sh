APP_VERSION=12.4
IMAGE='jellyfin/jellyfin:12.4@sha256:fea863d0cd9ec445985d9c75fc6ed64e38a1d2766cf0c250a33d553f4fc1b771'
APP_NOTE='Chép phim, nhạc vào /opt/jellyfin/media trên VPS rồi thêm thư viện (Bảng điều khiển → Thư viện) trỏ tới /media.'
JF_AUTH='MediaBrowser Client="Tino", Device="Tino 1-Click", DeviceId="tino-1click", Version="1.0"'

app_files() {
  cat > "$APP_DIR/compose.yaml" <<EOF
services:
  jellyfin:
    image: $IMAGE
    restart: unless-stopped
    environment:
      JELLYFIN_PublishedServerUrl: ${TINO_URL%/}
    volumes:
      - ./config:/config
      - ./cache:/cache
      - ./media:/media
    ports:
      - "127.0.0.1:$APP_PORT:8096"
EOF
}

# jf PHƯƠNG_THỨC ĐƯỜNG_DẪN [TOKEN] [tham số curl…]: gọi API với header Authorization kiểu MediaBrowser
jf() {
  local m=$1 p=$2 t=${3:-}
  shift 3
  api "$m" "$p" -H "Authorization: $JF_AUTH${t:+, Token=\"$t\"}" -H 'Content-Type: application/json' "$@"
}

# Làm hết trình hướng dẫn lần đầu qua /Startup/* (chỉ mở không cần đăng nhập khi chưa xong), trước khi mở HTTPS.
app_setup() {
  local tok net
  # healthcheck là /System/Info/Public: /health trả 200 sớm, API còn 503 trong lúc Jellyfin chạy migration (OTE 17/11)
  if api GET /System/Info/Public | jq -e '.StartupWizardCompleted != true' >/dev/null; then
    jf POST /Startup/Configuration '' -d '{"UICulture": "vi", "MetadataCountryCode": "VN", "PreferredMetadataLanguage": "vi"}' >/dev/null
    jf GET /Startup/User '' >/dev/null  # tạo người dùng đầu tiên
    # 403 nếu người dùng đầu tiên đã có mật khẩu (chạy lại giữa chừng): bước đăng nhập thử bên dưới sẽ kiểm
    jq -n --arg u "$ADMIN_USER" --arg p "$ADMIN_PW" '{Name: $u, Password: $p}' |
      jf POST /Startup/User '' --data-binary @- >/dev/null || true
    jf POST /Startup/RemoteAccess '' -d '{"EnableRemoteAccess": true}' >/dev/null
    jf POST /Startup/Complete '' >/dev/null
  fi
  tok=$(jq -n --arg u "$ADMIN_USER" --arg p "$ADMIN_PW" '{Username: $u, Pw: $p}' |
    jf POST /Users/AuthenticateByName '' --data-binary @- | jq -er 'select(.User.Policy.IsAdministrator == true) | .AccessToken')
  # Qua Caddy → docker, Jellyfin thấy mọi kết nối từ gateway mạng docker (172.x = LAN, vd. POST /System/Restart không cần
  # đăng nhập từ LAN). Tin X-Forwarded-For từ dải đó để biết IP thật; cấu hình này chỉ đọc lúc khởi động.
  net=$(jf GET /System/Configuration/network "$tok")
  if ! jq -e 'any(.KnownProxies[]?; . == "172.16.0.0/12")' <<<"$net" >/dev/null; then
    jq -c '.KnownProxies = (.KnownProxies // []) + ["172.16.0.0/12"]' <<<"$net" |
      jf POST /System/Configuration/network "$tok" --data-binary @- >/dev/null
    compose restart jellyfin
    wait_http "$APP_HEALTH" "$WAIT_SECS" || die 'Jellyfin không chạy lại sau khi đổi cấu hình mạng.'
  fi
}
