-- BigMenu patch | version: 1.0.1
-- ------------------------------------------------------------------
-- BigMenu — phóng to TOÀN BỘ menu của KOReader (user patch chính thức).
--
-- Menu KOReader mặc định chữ nhỏ, dòng thấp, rất khó chạm trên màn
-- hình e-ink. Patch này chạy lúc KOReader khởi động và:
--   * Menu chính / menu con (TouchMenu): chữ to hơn, dòng cao hơn,
--     ít mục mỗi trang hơn.
--   * Danh sách (Menu: thư viện sách, lịch sử...): ít mục mỗi trang,
--     chữ to hơn — qua đúng khóa cài đặt chính thức của KOReader
--     (items_per_page + items_font_size).
--   * Chữ giao diện chung (cfont), nhãn tab (ffont), tiêu đề (tfont)
--     nhỉnh hơn — nút bấm trong hộp thoại cũng cao theo.
--
-- Cài đặt: chép file này vào  .adds/koreader/patches/  rồi khởi động
-- lại KOReader. (Plugin bigmenu.koplugin có thể tự chép giúp file
-- này và tự cập nhật nó qua OTA.)
-- Gỡ bỏ: xóa file này rồi khởi động lại — mọi thứ về như cũ.
-- An toàn: từng mục đều bọc pcall; nếu bản KOReader tương lai đổi
-- cấu trúc nội bộ, mục đó tự bỏ qua thay vì làm lỗi khởi động.
-- ------------------------------------------------------------------

-- 1) Cỡ chữ danh nghĩa trong bảng Font.sizemap: TouchMenu dùng
--    "smallinfofont" cho từng mục menu, "ffont" cho nhãn tab,
--    hộp thoại và nút bấm dùng "cfont", tiêu đề dùng "tfont".
pcall(function()
    local Font = require("ui/font")
    Font.sizemap.smallinfofont = 28      -- mặc định 22
    Font.sizemap.smallinfofontbold = 28  -- mặc định 22
    Font.sizemap.ffont = 25              -- mặc định 20
    Font.sizemap.cfont = 27              -- mặc định 24
    Font.sizemap.tfont = 28              -- mặc định 26
end)

-- 2) Chiều cao dòng của TouchMenu + số mục tối đa mỗi trang.
--    Class TouchMenu lấy item_height từ Size.item.height_large
--    (mặc định scaleBySize(50)); ghi đè cả hai chỗ cho chắc.
pcall(function()
    local Device = require("device")
    local Screen = Device.screen
    local Size = require("ui/size")
    Size.item.height_default = Screen:scaleBySize(38)  -- mặc định 30
    Size.item.height_big = Screen:scaleBySize(48)      -- mặc định 40
    Size.item.height_large = Screen:scaleBySize(68)    -- mặc định 50
    local TouchMenu = require("ui/widget/touchmenu")
    TouchMenu.item_height = Screen:scaleBySize(68)
    TouchMenu.max_per_page_default = 8                 -- mặc định 10
end)

-- 3) Danh sách kiểu Menu (thư viện, lịch sử, bộ sưu tập...):
--    dùng khóa cài đặt chính thức của KOReader.
pcall(function()
    if G_reader_settings then
        G_reader_settings:saveSetting("items_per_page", 8)
        G_reader_settings:saveSetting("items_font_size", 26)
    end
end)
