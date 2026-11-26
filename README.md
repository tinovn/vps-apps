# Tino VPS Apps

Danh mục ứng dụng cài sẵn 1-Click trên VPS của [Tino](https://tino.vn). Khách chọn ứng dụng khi đặt VPS; khi VPS
chạy, hệ thống của Tino ghi `catalog/<slug>/install.sh` lên VPS và chạy bằng root. Mỗi script:

- kiểm cấu hình VPS (Ubuntu 24.04/26.04, CPU, RAM, đĩa), cài Docker và Caddy;
- chạy ứng dụng bằng Docker Compose, image ghim theo digest, cổng chỉ nghe `127.0.0.1`;
- tạo tài khoản quản trị (mật khẩu chỉ nằm trong `/root/tino-app.txt` trên VPS) rồi mới mở HTTPS bằng hostname của VPS;
- chạy lại nhiều lần được: giữ mật khẩu và dữ liệu cũ.

Danh sách ứng dụng, cấu hình tối thiểu và giấy phép của từng dự án gốc: [`catalog.json`](catalog.json).

## Cấu trúc

| Đường dẫn | Nội dung |
|---|---|
| `lib/install.sh` | Phần chung của mọi script; đầu tệp ghi giao ước (`##STEP`, `##NOTE`, `##ERROR`, mã thoát) |
| `catalog/<slug>/SKILL.md` | Metadata (frontmatter) và ghi chú cài đặt của ứng dụng |
| `catalog/<slug>/app.sh` | Phần riêng: `APP_VERSION`, `app_files` (viết `compose.yaml`), tuỳ chọn `app_setup` |
| `catalog/<slug>/install.sh`, `catalog.json` | Sinh tự động bởi `tools/gen_catalog.py`, không sửa tay |
| `images/<slug>/` | Ứng dụng không phát hành image chính thức: Tino tự build, đẩy lên `ghcr.io/tinovn` |
| `tools/pin_image.py` | In image kèm digest để ghim trong `app.sh` |

## Thêm hoặc sửa một ứng dụng

1. Viết `catalog/<slug>/SKILL.md` và `catalog/<slug>/app.sh`, theo một ứng dụng có sẵn cùng kiểu.
2. Ghim image: `python3 -I tools/pin_image.py <image>:<tag>`.
3. Sinh lại: `python3 -I tools/gen_catalog.py`.
4. Kiểm: `python3 -I -m unittest discover -s tests -v` (có `shellcheck` thì kiểm luôn).
5. Thử trên một VPS Ubuntu 24.04 trắng có tên miền trỏ về:
   `TINO_HOST=<tên miền> TINO_URL=https://<tên miền>/ bash catalog/<slug>/install.sh`

Pull request từ người ngoài tổ chức chỉ chạy workflow sau khi thành viên Tino duyệt.

## Giấy phép

Mỗi ứng dụng thuộc giấy phép của dự án gốc (trường `license` trong `catalog.json`). Image tự build trong `images/`
giữ nguyên `LICENSE` và `NOTICE` của dự án gốc.
