---
name: install-app
description: Cài Uptime Kuma 2.5.9 (Docker, SQLite) lên VPS Ubuntu 24.04 của khách Tino, tạo sẵn tài khoản quản trị rồi mới mở HTTPS qua Caddy.
metadata:
  repo: louislam/uptime-kuma
  ref: df601c58d9205562f34cfe5ef35264b341019d19
  category: monitoring
  title: Uptime Kuma
  summary_vi: Theo dõi website, API, máy chủ; báo qua Telegram, Zalo, email.
  min_cpu: 1
  min_ram_mb: 1024
  min_disk_gb: 10
  os: ubuntu-24.04
  port: 3001
  healthcheck: /
  license: MIT
---

# Cài Uptime Kuma

`ref` là commit của tag `2.5.9` (`gh api repos/louislam/uptime-kuma/git/ref/tags/2.5.9`, 12/11/2026). Cách cài chính thức là image Docker, nên không clone repo; image được ghim theo tag và digest của đúng bản 2.5.9 trên Docker Hub.

Thay `<HOST>` và `<URL>` bằng giá trị trong mục "Máy đích của job này" ở cuối luật Tino. Mọi tệp tạm viết vào `/job/skill/work/` bằng công cụ Write, rồi chép lên VPS bằng `scp`.

## OBJECTIVE

Uptime Kuma 2.5.9 chạy trong Docker trên VPS, chỉ nghe `127.0.0.1:3001`, có sẵn tài khoản quản trị `admin` với mật khẩu ngẫu nhiên, và mở ra ngoài qua Caddy tại `<URL>`.

## DONE WHEN

- `ssh vps 'curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:3001/'` in ra 2xx hoặc 3xx.
- `ssh vps 'curl -sk -o /dev/null -w "%{http_code}" --resolve <HOST>:443:127.0.0.1 https://<HOST>/'` in ra 2xx hoặc 3xx.
- `/root/tino-app.txt` có quyền 600 và đúng 3 dòng `url=<URL>`, `user=admin`, `password=…`.
- Script tạo quản trị (bước 6) in `login ok`.
- Cổng 3001 không mở ra ngoài: `ssh vps 'ss -ltn | grep -c "0.0.0.0:3001"'` in `0`.

## Các bước

### 1. Kiểm tra máy

```bash
ssh vps '. /etc/os-release; echo "$ID $VERSION_ID"; nproc; free -m | awk "/Mem:/{print \$2}"; df -BG --output=avail / | tail -1'
```

Cần `ubuntu 24.04` hoặc `ubuntu 26.04` (template Proxmox của OTE là 26.04; cả hai có đủ `docker.io`, `docker-compose-v2`, `caddy`), ít nhất 1 CPU, RAM từ khoảng 900 MB, đĩa trống từ 5G. Không đạt thì dừng với `status: failed` và `error_vi` nêu đúng thứ thiếu.

### 2. Cài Docker, Caddy

Dùng gói của Ubuntu, không thêm kho ngoài. Máy mới tạo thường đang chạy `unattended-upgrades`, nên chờ khoá dpkg:

```bash
ssh vps 'export DEBIAN_FRONTEND=noninteractive; apt-get -o DPkg::Lock::Timeout=600 update -q && apt-get -o DPkg::Lock::Timeout=600 install -yq docker.io docker-compose-v2 caddy curl && systemctl enable --now docker && docker compose version'
```

### 3. Tệp compose

Viết `/job/skill/work/compose.yaml` đúng nội dung sau:

```yaml
services:
  uptime-kuma:
    image: louislam/uptime-kuma:2.5.9@sha256:e88415a90dd2f7efecdbc18de0490aff292764a3ac471531bf1d0481725591bd
    container_name: uptime-kuma
    restart: unless-stopped
    environment:
      # Có biến này thì Uptime Kuma 2.x bỏ qua trang chọn cơ sở dữ liệu lần đầu.
      UPTIME_KUMA_DB_TYPE: sqlite
    volumes:
      - ./data:/app/data
    ports:
      - "127.0.0.1:3001:3001"
```

```bash
ssh vps 'install -d -m 755 /opt/uptime-kuma'
scp /job/skill/work/compose.yaml vps:/opt/uptime-kuma/compose.yaml
ssh vps 'cd /opt/uptime-kuma && docker compose pull -q && docker compose up -d'
```

### 4. Chờ ứng dụng lên

```bash
ssh vps 'for i in $(seq 1 60); do c=$(curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:3001/); case "$c" in 2*|3*) echo "ok $c"; exit 0;; esac; sleep 3; done; docker logs --tail 40 uptime-kuma; exit 1'
```

### 5. Sinh mật khẩu quản trị trên VPS (trước khi mở HTTPS)

Mật khẩu sinh và nằm trên VPS; không in ra, không đọc tệp này về. Lần chạy lại thì giữ mật khẩu cũ.

```bash
ssh vps 'umask 077; if ! grep -q "^password=." /root/tino-app.txt 2>/dev/null; then PW="$(tr -dc A-Za-z0-9 </dev/urandom | head -c 20)-Tk9"; printf "url=%s\nuser=%s\npassword=%s\n" "<URL>" "admin" "$PW" > /root/tino-app.txt; fi; sed -i "s#^url=.*#url=<URL>#" /root/tino-app.txt; chmod 600 /root/tino-app.txt; grep -c "^[a-z]*=." /root/tino-app.txt'
```

Phải in `3`.

### 6. Tạo tài khoản quản trị

Uptime Kuma **không có lệnh CLI hay biến môi trường để tạo admin đầu tiên**: trang web lần đầu gọi sự kiện socket.io `setup` (khi chưa có user nào). Bước này gọi đúng sự kiện đó từ trong container, lúc cổng còn chỉ mở ở `127.0.0.1`, rồi đăng nhập thử bằng cùng mật khẩu. `socket.io-client` có sẵn trong image (nằm ở `dependencies`).

Viết `/job/skill/work/kuma-setup.js` đúng nội dung sau:

```js
// Tạo admin đầu tiên qua sự kiện "setup" như trang web, rồi đăng nhập thử. Không in mật khẩu.
const { io } = require("/app/node_modules/socket.io-client");
const user = process.env.KUMA_USER;
const pass = process.env.KUMA_PW;
const s = io("http://127.0.0.1:3001", { transports: ["websocket"], reconnection: false, timeout: 15000 });
const end = (code, msg) => { console.log(msg); s.close(); process.exit(code); };
setTimeout(() => end(1, "timeout"), 30000);
s.on("connect_error", (e) => end(1, "connect_error " + e.message));
s.on("connect", () => {
  s.emit("needSetup", (need) => {
    const login = () => s.emit("login", { username: user, password: pass, token: "" }, (r) =>
      end(r && r.ok ? 0 : 1, r && r.ok ? "login ok" : "login failed " + (r && r.msg)));
    if (!need) return login();
    s.emit("setup", user, pass, (r) => (r && r.ok ? login() : end(1, "setup failed " + (r && r.msg))));
  });
});
```

```bash
scp /job/skill/work/kuma-setup.js vps:/root/.tino-kuma-setup.js
ssh vps 'U="$(sed -n "s/^user=//p" /root/tino-app.txt)"; PW="$(sed -n "s/^password=//p" /root/tino-app.txt)"; docker exec -i -e KUMA_USER="$U" -e KUMA_PW="$PW" uptime-kuma node - < /root/.tino-kuma-setup.js; rc=$?; rm -f /root/.tino-kuma-setup.js; exit $rc'
```

Phải in `login ok`. Nếu in `login failed` thì Uptime Kuma đã có quản trị từ trước với mật khẩu khác: **dừng**, báo `failed` với `error_vi` "Uptime Kuma trên VPS đã có tài khoản quản trị từ trước". Không xoá dữ liệu, không đặt lại mật khẩu.

### 7. Mở HTTPS qua Caddy

Viết `/job/skill/work/Caddyfile` (thay `<HOST>`):

```
<HOST> {
	reverse_proxy 127.0.0.1:3001
}
```

```bash
scp /job/skill/work/Caddyfile vps:/etc/caddy/Caddyfile
ssh vps 'caddy validate --config /etc/caddy/Caddyfile --adapter caddyfile && systemctl enable caddy && systemctl reload-or-restart caddy'
ssh vps 'if ufw status 2>/dev/null | grep -q "Status: active"; then ufw allow 80/tcp && ufw allow 443/tcp; fi; echo ufw-ok'
ssh vps 'for i in $(seq 1 24); do c=$(curl -sk -o /dev/null -w "%{http_code}" --resolve <HOST>:443:127.0.0.1 https://<HOST>/); case "$c" in 2*|3*) echo "ok $c"; exit 0;; esac; sleep 5; done; echo "chua-co-chung-chi $c"; journalctl -u caddy -n 30 --no-pager; exit 1'
```

Nếu sau 2 phút vẫn chưa được (Let's Encrypt không cấp được chứng chỉ), thêm dòng `tls internal` vào khối site trong `/job/skill/work/Caddyfile`, chép lại, reload, kiểm lại bằng lệnh trên. Khi dùng `tls internal`, ghi vào `notes_vi`: "Trình duyệt sẽ cảnh báo chứng chỉ cho tới khi tên miền được trỏ về VPS."

### 8. Kiểm lần cuối và kết thúc

```bash
ssh vps 'curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:3001/; ss -ltn | grep -c "0.0.0.0:3001"; stat -c %a /root/tino-app.txt; docker ps --filter name=uptime-kuma --format "{{.Status}}"'
```

Kết thúc bằng JSON kết quả, ví dụ `{"status": "success", "notes_vi": "Đăng nhập bằng tài khoản admin trong thông tin dịch vụ."}`. Không đưa mật khẩu vào JSON.
