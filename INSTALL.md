# Cài đặt Big Menu cho KOReader — hướng dẫn chi tiết

Tài liệu này hướng dẫn cài **Big Menu** (bảng biểu tượng ô to + patch
phóng to toàn bộ menu KOReader) lên máy đọc sách chạy KOReader
(ví dụ Kobo Sage). Đọc README.md nếu muốn hiểu cơ chế bên trong.

## Bạn cần có

- Máy đọc sách **đã cài KOReader** (Big Menu là plugin + patch *của*
  KOReader, không phải phần mềm riêng).
- Cáp USB nối máy đọc sách với máy tính (chỉ cho lần cài đầu tiên —
  mọi lần cập nhật sau đều qua OTA, không cần cáp nữa).
- File của dự án: tải bản đóng gói `BigMenu-v<x.y.z>.zip` ở mục
  Releases của repo này, hoặc chép thẳng từ cây thư mục repo.

## Cấu trúc thư mục trên máy đọc sách

Sau khi cài xong, trên máy sẽ có:

```
.adds/koreader/
├─ plugins/
│  └─ bigmenu.koplugin/        ← bạn chép vào (bước 2)
│     ├─ main.lua
│     └─ _meta.lua
└─ patches/
   └─ 2-bigmenu.lua            ← plugin tự chép giúp (bước 4),
                                  hoặc bạn tự chép ở bước 3
```

## Các bước cài đặt

### Bước 1 — Nối máy đọc sách với máy tính

Cắm cáp USB. Trên Kobo, khi được hỏi thì chọn chế độ kết nối máy tính
(USB storage). Máy đọc sách hiện thành một ổ đĩa trên máy tính
(ví dụ ổ `D:` tên `KOBOeReader` trên Windows).

### Bước 2 — Chép thư mục plugin

Chép **cả thư mục** `bigmenu.koplugin` (có `main.lua` và `_meta.lua`
bên trong) vào:

```
<ổ của máy đọc sách>/.adds/koreader/plugins/
```

Lưu ý: thư mục `.adds` có thể bị ẩn — bật hiện file/thư mục ẩn trong
trình quản lý file của máy tính nếu chưa thấy.

### Bước 3 (không bắt buộc) — Tự chép patch

Nếu muốn chắc chắn, chép thêm file `patches/2-bigmenu.lua` của repo
vào:

```
<ổ của máy đọc sách>/.adds/koreader/patches/
```

(chưa có thư mục `patches` thì tạo mới). Bỏ qua bước này cũng được:
plugin sẽ tự làm ở bước 4.

### Bước 4 — Rút cáp an toàn và khởi động lại KOReader

Tháo ổ đĩa an toàn (Eject) trước khi rút cáp. Trên máy đọc sách, mở
KOReader; nếu KOReader đang chạy sẵn thì **thoát hẳn rồi mở lại**
(plugin chỉ được nạp khi KOReader khởi động).

Sau đó mở menu **Công cụ (Tools)** một lần. Plugin sẽ tự kiểm tra và
chép patch vào `patches/`, hiện thông báo
*“Đã cài patch Menu To. Khởi động lại KOReader để menu to có hiệu lực.”*

### Bước 5 — Khởi động lại KOReader lần nữa

Patch chỉ chạy lúc KOReader khởi động. Sau lần khởi động lại này:

- mọi menu của KOReader đã to hơn (dòng cao, chữ lớn);
- trong menu **Công cụ → Big Menu — bảng biểu tượng** có mục
  *Mở bảng biểu tượng*, *Cập nhật bản mới (OTA)* và dòng phiên bản.

### Bước 6 (nên làm) — Gán cử chỉ mở bảng biểu tượng

Để mở bảng biểu tượng từ bất cứ đâu (kể cả giữa trang sách) mà không
cần vào menu:

1. Mở phần cài đặt **cử chỉ (Gestures)** của KOReader.
2. Chọn một cử chỉ ít dùng (ví dụ chạm giữ một góc màn hình).
3. Gán cho nó hành động **“Big Menu — bảng biểu tượng”**
   (nhóm hành động chung / Dispatcher).

Từ đó, một cử chỉ là ra cả bảng ô to.

## Cập nhật các lần sau — OTA, không cần cáp

1. Bật Wi-Fi trên máy đọc sách.
2. Mở **Công cụ → Big Menu → Cập nhật bản mới (OTA, cần Wi-Fi)**
   (hoặc chạm ô **Cập nhật bản mới** trong bảng biểu tượng).
3. Nếu có bản mới, plugin tự tải cả plugin lẫn patch mới, giữ lại
   bản sao lưu `main.lua.bak`, rồi báo khởi động lại KOReader.
4. Khởi động lại KOReader — xong.

Plugin **chỉ nâng cấp khi bản trên mạng mới hơn**; bản trên máy mới
hơn sẽ không bị “cập nhật ngược” xuống bản cũ.

## Gỡ cài đặt

1. Xóa thư mục `.adds/koreader/plugins/bigmenu.koplugin/`.
2. Xóa file `.adds/koreader/patches/2-bigmenu.lua`.
3. Khởi động lại KOReader — giao diện về nguyên bản.
4. (Tùy chọn) Hai khóa `items_per_page` và `items_font_size` do patch
   ghi vào cài đặt KOReader vẫn còn; xóa hai dòng đó trong file
   `.adds/koreader/settings.reader.lua` nếu muốn KOReader tự tính lại
   như mặc định.

## Kiểm tra nhanh sau khi cài

- [ ] Menu Công cụ có mục **Big Menu — bảng biểu tượng**.
- [ ] Mở bảng biểu tượng thấy 7 ô to: Thư viện sách, Sách đọc gần
      đây, Bộ sưu tập, Đèn nền, Wi-Fi, Cập nhật bản mới, Đóng bảng.
- [ ] Menu gốc của KOReader (ví dụ menu ở màn hình thư viện) có dòng
      cao và chữ to hơn trước.
- [ ] Chạm ô **Đèn nền** thấy đèn bật/tắt; ô **Wi-Fi** đổi trạng thái
      mạng (hai phép thử không hại gì).

Có mục nào không đạt, xem bảng xử lý sự cố trong README.md.
