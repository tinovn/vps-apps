---
name: install-app
description: Cài LibreTranslate 1.9.6 (Docker, mô hình Anh/Việt/Trung/Nhật/Hàn/Pháp) lên VPS Ubuntu của khách Tino, chặn người lạ bằng Basic auth của Caddy.
metadata:
  repo: LibreTranslate/LibreTranslate
  ref: 497f6c678bdb175ff0baa75b9865d70f1ed8d108
  category: ai
  title: LibreTranslate
  summary_vi: Máy dịch tự chạy trên VPS, có trang web và API, không gửi văn bản ra ngoài.
  min_cpu: 2
  min_ram_mb: 2048
  min_disk_gb: 20
  os: ubuntu-24.04
  port: 5000
  healthcheck: /health
  license: AGPL-3.0
---

# LibreTranslate

`ref` = commit của tag `v1.9.6`; image `libretranslate/libretranslate:v1.9.6` ghim theo digest. Lần đầu `scripts/entrypoint.sh` tải mô hình
(`libretranslate/init.py`, giới hạn bởi `LT_LOAD_ONLY`) rồi mới chạy gunicorn, nên `/health` chỉ trả lời khi đã sẵn sàng; mô hình giữ trong volume thư mục nhà.
Không có đăng nhập: `APP_AUTH=basic` (Caddy hỏi tài khoản cho cả web lẫn API); kiểm bằng dịch thử `POST /translate` en→vi qua 127.0.0.1.
