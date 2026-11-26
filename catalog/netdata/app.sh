APP_VERSION=2.12.3
IMAGE='netdata/netdata:v2.12.3@sha256:c7eab00e20901eb60595ebae0fbfe88e59464e663924461874719d40de0735d2'
APP_AUTH=basic  # dashboard cục bộ của Netdata không có đăng nhập
APP_NOTE='Số liệu VPS xem được ngay; vài tính năng (Functions, lưu dashboard) cần đăng nhập Netdata Cloud.'

# Theo docker-compose chính thức (packaging/docker/README.md): mạng host, pid host, mount /proc, /sys… chỉ đọc.
# Mạng host nên phải ép web server chỉ nghe 127.0.0.1 ("-W set" ghi đè netdata.conf); statsd mặc định đã chỉ nghe localhost.
app_files() {
  cat > "$APP_DIR/compose.yaml" <<EOF
services:
  netdata:
    image: $IMAGE
    container_name: netdata
    pid: host
    network_mode: host
    restart: unless-stopped
    command: ["-W", "set", "web", "bind to", "127.0.0.1"]
    cap_add:
      - SYS_PTRACE
      - SYS_ADMIN
    security_opt:
      - apparmor:unconfined
    environment:
      DO_NOT_TRACK: "1"
      NETDATA_LISTENER_PORT: "$APP_PORT"
      NETDATA_HEALTHCHECK_TARGET: http://127.0.0.1:$APP_PORT/api/v1/info
    volumes:
      - netdataconfig:/etc/netdata
      - netdatalib:/var/lib/netdata
      - netdatacache:/var/cache/netdata
      - /:/host/root:ro,rslave
      - /etc/passwd:/host/etc/passwd:ro
      - /etc/group:/host/etc/group:ro
      - /etc/localtime:/etc/localtime:ro
      - /proc:/host/proc:ro
      - /sys:/host/sys:ro
      - /etc/os-release:/host/etc/os-release:ro
      - /var/log:/host/var/log:ro
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /run/dbus:/run/dbus:ro
volumes:
  netdataconfig:
  netdatalib:
  netdatacache:
EOF
}
