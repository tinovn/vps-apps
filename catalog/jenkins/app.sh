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
