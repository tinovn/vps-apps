APP_VERSION=5.0.3
IMAGE='healthchecks/healthchecks:v5.0.3@sha256:5eb96eb72dc63ac24743f1c0fc4469931155329e05c9781a0809320de0ae479c'
ADMIN_USER="admin@$TINO_HOST"  # Healthchecks đăng nhập bằng email
APP_NOTE='Đăng ký tự do đang tắt. Cảnh báo qua email cần khai báo SMTP (EMAIL_HOST…) trong /opt/healthchecks/compose.yaml; webhook, ntfy dùng được ngay.'

app_files() {
  secret SECRET_KEY 50
  cat > "$APP_DIR/compose.yaml" <<EOF
services:
  healthchecks:
    image: $IMAGE
    container_name: healthchecks
    restart: unless-stopped
    environment:
      DEBUG: "False"
      SECRET_KEY: \${SECRET_KEY}
      SITE_ROOT: ${TINO_URL%/}
      SITE_NAME: Healthchecks
      ALLOWED_HOSTS: $TINO_HOST
      REGISTRATION_OPEN: "False"
      DB_NAME: /data/hc.sqlite
      DEFAULT_FROM_EMAIL: healthchecks@$TINO_HOST
      GUNICORN_WORKERS: "2"
    volumes:
      # named volume: giữ quyền /data của user hc trong image
      - hc-data:/data
    ports:
      - "127.0.0.1:$APP_PORT:8000"
volumes:
  hc-data:
EOF
}

# createsuperuser của Healthchecks chỉ nhận mật khẩu qua --password (hc/accounts/management/commands/createsuperuser.py):
# làm đúng các bước của lệnh đó trong manage.py shell, mật khẩu qua biến môi trường; có rồi thì chỉ đăng nhập thử.
app_setup() {
  local py rc=0
  py=$(cat <<'EOF'
import os, sys
from django.contrib.auth import authenticate
from django.contrib.auth.models import User
from hc.accounts.views import _make_user
email, pw = os.environ["HC_EMAIL"], os.environ["HC_PW"]
if not User.objects.filter(email=email).exists():
    u = _make_user(email)
    u.set_password(pw)
    u.is_staff = u.is_superuser = True
    u.save()
u = authenticate(username=email, password=pw)
sys.exit(0 if u is not None and u.is_superuser else 2)
EOF
)
  HC_EMAIL=$ADMIN_USER HC_PW=$ADMIN_PW docker exec -e HC_EMAIL -e HC_PW healthchecks ./manage.py shell -c "$py" >/dev/null || rc=$?
  [ "$rc" -ne 2 ] || refuse 'Healthchecks trên VPS đã có tài khoản quản trị từ trước với mật khẩu khác.'
  [ "$rc" -eq 0 ] || exit 1
}
