APP_VERSION=1.9.6
IMAGE='libretranslate/libretranslate:v1.9.6@sha256:1de2d7056bb8ad607a412f4563d9abe324ff632b43b5be9428bcc8e213aebb32'
APP_AUTH=basic  # LibreTranslate không có đăng nhập: Caddy hỏi tài khoản cho cả trang web lẫn API
WAIT_SECS=900   # lần đầu tải mô hình dịch (~1 GB) trước khi máy chủ nghe cổng
APP_NOTE='Có sẵn tiếng Anh, Việt, Trung, Nhật, Hàn, Pháp. Gọi API bằng Basic auth với cùng tài khoản, vd. curl -u admin:<mật khẩu> -d q=Hello -d source=en -d target=vi <địa chỉ>/translate.'

app_files() {
  cat > "$APP_DIR/compose.yaml" <<EOF
services:
  libretranslate:
    image: $IMAGE
    container_name: libretranslate
    restart: unless-stopped
    environment:
      LT_LOAD_ONLY: en,vi,zh,ja,ko,fr
      LT_THREADS: "2"  # số worker gunicorn, mỗi worker nạp mô hình riêng (mặc định 4 quá nặng cho 2 GB RAM)
    volumes:
      # mô hình argos ở ~/.local, mô hình tách câu MiniSBD ở ~/.cache: giữ cả thư mục nhà (uid 1032)
      - home:/home/libretranslate
    ports:
      - "127.0.0.1:$APP_PORT:5000"
volumes:
  home:
EOF
}

# Không có tài khoản để tạo: dịch thử một câu để chắc mô hình đã tải và nạp được.
app_setup() {
  jq -n '{q: "Hello world", source: "en", target: "vi", format: "text"}' |
    api POST /translate -H 'Content-Type: application/json' --data-binary @- | jq -e '.translatedText | length > 0' >/dev/null
}
