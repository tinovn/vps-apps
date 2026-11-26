APP_VERSION=2.5.9
IMAGE='louislam/uptime-kuma:2.5.9@sha256:e88415a90dd2f7efecdbc18de0490aff292764a3ac471531bf1d0481725591bd'

app_files() {
  cat > "$APP_DIR/compose.yaml" <<EOF
services:
  uptime-kuma:
    image: $IMAGE
    container_name: uptime-kuma
    restart: unless-stopped
    environment:
      # Có biến này thì Uptime Kuma 2.x bỏ qua trang chọn cơ sở dữ liệu lần đầu.
      UPTIME_KUMA_DB_TYPE: sqlite
    volumes:
      - ./data:/app/data
    ports:
      - "127.0.0.1:$APP_PORT:3001"
EOF
}

# Uptime Kuma không có CLI / biến môi trường tạo admin đầu tiên: gọi sự kiện socket.io "setup" như trang web, rồi đăng nhập thử.
app_setup() {
  # HTTP trả lời trước khi socket.io nhận "setup": OTE 17/11 job 3 tạo admin ngay thì timeout, 30 s sau (healthy) thì được
  for _ in $(seq 1 60); do
    [ "$(docker inspect -f '{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' uptime-kuma)" != starting ] && break
    sleep 3
  done
  local setup_js rc
  setup_js=$(cat <<'EOF'
const { io } = require("/app/node_modules/socket.io-client");
const user = process.env.KUMA_USER, pass = process.env.KUMA_PW;
const s = io("http://127.0.0.1:3001", { transports: ["websocket"], reconnection: false, timeout: 15000 });
const end = (code, msg) => { console.log(msg); s.close(); process.exit(code); };
setTimeout(() => end(1, "timeout"), 30000);
s.on("connect_error", (e) => end(1, "connect_error " + e.message));
s.on("connect", () => {
  s.emit("needSetup", (need) => {
    const login = () => s.emit("login", { username: user, password: pass, token: "" }, (r) =>
      end(r && r.ok ? 0 : 2, r && r.ok ? "login ok" : "login failed " + (r && r.msg)));
    if (!need) return login();
    s.emit("setup", user, pass, (r) => (r && r.ok ? login() : end(1, "setup failed " + (r && r.msg))));
  });
});
EOF
)
  for try in 1 2 3 4 5 6; do  # timeout / connect_error khi máy chủ còn khởi động: thử lại
    rc=0
    KUMA_USER=$ADMIN_USER KUMA_PW=$ADMIN_PW docker exec -i -e KUMA_USER -e KUMA_PW uptime-kuma node - <<<"$setup_js" || rc=$?
    [ "$rc" -ne 2 ] || refuse 'Uptime Kuma trên VPS đã có tài khoản quản trị từ trước với mật khẩu khác.'
    [ "$rc" -ne 0 ] || return 0
    [ "$try" -lt 6 ] || exit 1
    sleep 10
  done
}
