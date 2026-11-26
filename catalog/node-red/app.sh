APP_VERSION=5.0.9
IMAGE='nodered/node-red:5.0.9@sha256:2ccd38b4066648bd5e17430c50a2f8102c566a82fd4f2fc5c342e61664d6896f'

app_files() {
  secret CRED_SECRET 48
  install -d -m 755 -o 1000 -g 1000 "$APP_DIR/data"
  # settings.js = bản mặc định của đúng image + adminAuth (hash bcrypt sinh trong container, mật khẩu qua biến môi trường).
  # Đã có thì giữ: khách có thể đã sửa.
  if [ ! -s "$APP_DIR/data/settings.js" ]; then
    local js
    js=$(cat <<'EOF'
const fs = require("fs");
const nr = "/usr/src/node-red/node_modules/node-red";
const bcrypt = require(require.resolve("bcryptjs", { paths: [nr] }));
const users = [{ username: process.env.NR_USER, password: bcrypt.hashSync(process.env.NR_PW, 10), permissions: "*" }];
process.stdout.write(fs.readFileSync(nr + "/settings.js", "utf8") +
  "\n// Tino 1-Click: đăng nhập trình soạn thảo, khoá mã hoá credentials\n" +
  "module.exports.adminAuth = { type: \"credentials\", users: " + JSON.stringify(users) + " };\n" +
  "module.exports.credentialSecret = process.env.NODE_RED_CREDENTIAL_SECRET;\n");
EOF
)
    NR_USER=$ADMIN_USER NR_PW=$ADMIN_PW docker run --rm -i -e NR_USER -e NR_PW --entrypoint node "$IMAGE" - <<<"$js" > "$APP_DIR/data/settings.js.tmp"
    grep -q 'module.exports.adminAuth' "$APP_DIR/data/settings.js.tmp" || die 'Không tạo được settings.js cho Node-RED.'
    chown 1000:1000 "$APP_DIR/data/settings.js.tmp"
    chmod 600 "$APP_DIR/data/settings.js.tmp"
    mv "$APP_DIR/data/settings.js.tmp" "$APP_DIR/data/settings.js"
  fi
  cat > "$APP_DIR/compose.yaml" <<EOF
services:
  node-red:
    image: $IMAGE
    container_name: node-red
    restart: unless-stopped
    environment:
      TZ: Asia/Ho_Chi_Minh
      NODE_RED_CREDENTIAL_SECRET: \${CRED_SECRET}
    volumes:
      - ./data:/data
    ports:
      - "127.0.0.1:$APP_PORT:1880"
EOF
}

# đăng nhập thử: OAuth password grant của trình soạn thảo (POST /auth/token)
app_setup() {
  jq -n --arg u "$ADMIN_USER" --arg p "$ADMIN_PW" \
    '{client_id: "node-red-admin", grant_type: "password", scope: "*", username: $u, password: $p}' |
    api POST /auth/token -H 'Content-Type: application/json' --data-binary @- | jq -e '.access_token | length > 0' >/dev/null
}
