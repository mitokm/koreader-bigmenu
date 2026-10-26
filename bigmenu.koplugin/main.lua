-- BigMenu — bảng biểu tượng ô to + menu to cho KOReader.
--
-- Hai thành phần phối hợp:
--  1) Plugin này: bảng "Bảng chính" gồm các ô biểu tượng TO (thư viện,
--     sách gần đây, bộ sưu tập, đèn nền, Wi-Fi...) mở từ menu Công cụ
--     hoặc bằng một cử chỉ gán qua Dispatcher — khỏi mò menu chữ nhỏ.
--  2) Patch 2-bigmenu.lua (thư mục patches/ cạnh plugins/): phóng to
--     toàn bộ menu gốc của KOReader. Plugin TỰ chép/cập nhật patch
--     này (lần đầu và mỗi lần OTA) nên người dùng chỉ cần cài plugin.
--
-- Cập nhật OTA: menu của plugin có mục "Cập nhật bản mới (OTA)" —
-- tải main.lua + _meta.lua + patch mới nhất từ GitHub, giữ bản sao
-- lưu .bak, chỉ nâng cấp khi bản trên mạng mới hơn bản trên máy.

local Blitbuffer = require("ffi/blitbuffer")
local Device = require("device")
local Event = require("ui/event")
local ffiutil = require("ffi/util")
local Font = require("ui/font")
local FrameContainer = require("ui/widget/container/framecontainer")
local Geom = require("ui/geometry")
local GestureRange = require("ui/gesturerange")
local HorizontalGroup = require("ui/widget/horizontalgroup")
local HorizontalSpan = require("ui/widget/horizontalspan")
local InfoMessage = require("ui/widget/infomessage")
local InputContainer = require("ui/widget/container/inputcontainer")
local CenterContainer = require("ui/widget/container/centercontainer")
local TextWidget = require("ui/widget/textwidget")
local UIManager = require("ui/uimanager")
local VerticalGroup = require("ui/widget/verticalgroup")
local VerticalSpan = require("ui/widget/verticalspan")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local _ = require("gettext")

local Screen = Device.screen

-- Giây dạng thập phân từ đồng hồ đơn điệu (nhận diện chạm 2 lần).
local function nowSeconds()
    local ok, s, u = pcall(ffiutil.gettime)
    if ok and s then return s + u / 1000000 end
    return os.time()
end

local BIGMENU_VERSION = "1.0.4"
local OTA_BASE = "https://raw.githubusercontent.com/mitokm/koreader-bigmenu/main/"
local PATCH_NAME = "2-bigmenu.lua"

-- Nội dung patch đi kèm (bản sao y hệt patches/2-bigmenu.lua trong
-- repo — script đóng gói tự chèn vào đây, đừng sửa tay dòng dưới).
local PATCH_SOURCE = [==[
-- BigMenu patch | version: 1.0.4
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
]==]

local function pluginDir()
    local src = debug.getinfo(1, "S").source or ""
    return src:match("^@(.*/)") or "./"
end

local function patchesDir()
    return pluginDir() .. "../../patches/"
end

local function readFile(path)
    local f = io.open(path, "rb")
    if not f then return nil end
    local data = f:read("*a")
    f:close()
    return data
end

local function patchVersionOf(text)
    if not text then return nil end
    return text:match("BigMenu patch | version:%s*([%d%.]+)")
end

local function versionParts(v)
    local t = {}
    for n in tostring(v):gmatch("%d+") do t[#t + 1] = tonumber(n) end
    return t
end

local function isNewer(remote, local_v)
    local rp, lp = versionParts(remote), versionParts(local_v)
    for i = 1, math.max(#rp, #lp) do
        local a, b = rp[i] or 0, lp[i] or 0
        if a > b then return true end
        if a < b then return false end
    end
    return false
end

local function httpGet(url)
    local https = require("ssl.https")
    local ltn12 = require("ltn12")
    local chunks = {}
    local res, code = https.request{
        url = url,
        sink = ltn12.sink.table(chunks),
    }
    if res and (code == 200 or code == "200") then
        return table.concat(chunks)
    end
    return nil
end

----------------------------------------------------------------------
-- Ô biểu tượng trong bảng chính
----------------------------------------------------------------------

local Tile = InputContainer:extend{
    icon = "",
    label = "",
    tap_callback = nil,
    tile_w = 0,
    tile_h = 0,
}

function Tile:init()
    self.dimen = Geom:new{ w = self.tile_w, h = self.tile_h, x = 0, y = 0 }
    self.ges_events = {
        TapSelect = { GestureRange:new{ ges = "tap", range = self.dimen } },
    }
    local inner = math.max(10, self.tile_w - Screen:scaleBySize(28))
    local inner_h = math.max(10, self.tile_h - Screen:scaleBySize(28))
    self[1] = FrameContainer:new{
        bordersize = Screen:scaleBySize(3),
        padding = Screen:scaleBySize(12),
        CenterContainer:new{
            dimen = Geom:new{ w = inner, h = inner_h },
            VerticalGroup:new{
                align = "center",
                -- LƯU Ý: Font:getFace TỰ scale theo DPI — truyền số thô,
                -- bọc scaleBySize ở ngoài sẽ bị phóng to 2 lần.
                TextWidget:new{
                    text = self.icon,
                    face = Font:getFace("cfont", 46),
                },
                VerticalSpan:new{ width = Screen:scaleBySize(12) },
                TextWidget:new{
                    text = self.label,
                    face = Font:getFace("cfont", 25),
                    bold = true,
                },
            },
        },
    }
end

function Tile:onTapSelect()
    if self.tap_callback then self.tap_callback() end
    return true
end

----------------------------------------------------------------------
-- Nút Đóng: nhỏ gọn, KHÔNG khung — chỉ còn dấu ✕ + chữ nằm ngang
----------------------------------------------------------------------

local CloseTile = InputContainer:extend{
    label = "",
    tap_callback = nil,
    tile_w = 0,
    tile_h = 0,
}

function CloseTile:init()
    self.dimen = Geom:new{ w = self.tile_w, h = self.tile_h, x = 0, y = 0 }
    self.ges_events = {
        TapSelect = { GestureRange:new{ ges = "tap", range = self.dimen } },
    }
    self[1] = CenterContainer:new{
        dimen = Geom:new{ w = self.tile_w, h = self.tile_h },
        HorizontalGroup:new{
            align = "center",
            TextWidget:new{
                text = "\239\128\141",
                face = Font:getFace("cfont", 30),
            },
            HorizontalSpan:new{ width = Screen:scaleBySize(14) },
            TextWidget:new{
                text = self.label,
                face = Font:getFace("cfont", 25),
                bold = true,
            },
        },
    }
end

function CloseTile:onTapSelect()
    if self.tap_callback then self.tap_callback() end
    return true
end

----------------------------------------------------------------------
-- Bảng chính: lưới ô biểu tượng toàn màn hình
----------------------------------------------------------------------

local HomePanel = InputContainer:extend{
    covers_fullscreen = true,
    tiles = nil, -- mảng { icon=, label=, fn= }
    tile_widgets = nil, -- các Tile đã dựng (để nhận biết chạm trúng ô)
    on_exit = nil, -- gọi khi người dùng chạm 2 lần vào nền
    hint = nil, -- dòng ghi chú dưới lưới ô
    _last_bg_tap = nil,
}

-- Bảng nuốt mọi chạm để thao tác không lọt xuống màn hình dưới.
-- Riêng việc THOÁT bảng bằng nền: phải chạm 2 lần liên tiếp (≤ 0,6 s)
-- như đồng hồ Sage Clock — chạm 1 lần không làm gì cả.
function HomePanel:onSwallowTap(arg, ges)
    if ges and ges.pos and self.tile_widgets then
        for _, w in ipairs(self.tile_widgets) do
            local d = w.dimen
            if d and d.w and d.w > 0
                and ges.pos.x >= d.x and ges.pos.x < d.x + d.w
                and ges.pos.y >= d.y and ges.pos.y < d.y + d.h then
                return true -- chạm trúng ô: ô tự xử lý
            end
        end
    end
    local now = nowSeconds()
    if self._last_bg_tap and (now - self._last_bg_tap) <= 0.6 then
        self._last_bg_tap = nil
        if self.on_exit then self.on_exit() end
    else
        self._last_bg_tap = now
    end
    return true
end
function HomePanel:onSwallowSwipe() return true end

function HomePanel:init()
    local W = Screen:getWidth()
    self.dimen = Geom:new{ x = 0, y = 0, w = W, h = Screen:getHeight() }
    self.ges_events = {
        SwallowTap = { GestureRange:new{ ges = "tap", range = self.dimen } },
        SwallowSwipe = { GestureRange:new{ ges = "swipe", range = self.dimen } },
    }
    local cols = 2
    local tile_w = math.floor(W * 0.42)
    local tile_h = Screen:scaleBySize(150)
    local rows = {
        TextWidget:new{
            text = _("Bảng chính"),
            face = Font:getFace("cfont", 34),
            bold = true,
        },
        VerticalSpan:new{ width = Screen:scaleBySize(48) },
    }
    local row = HorizontalGroup:new{}
    self.tile_widgets = {}
    for i, def in ipairs(self.tiles or {}) do
        if i > 1 and (i - 1) % cols == 0 then
            rows[#rows + 1] = row
            rows[#rows + 1] = VerticalSpan:new{ width = Screen:scaleBySize(18) }
            row = HorizontalGroup:new{}
        elseif i > 1 then
            row[#row + 1] = HorizontalSpan:new{ width = math.floor(W * 0.04) }
        end
        local tile
        if def.plain then
            -- Ô dạng nút gọn không khung (nút Đóng): thấp hơn hẳn ô thường.
            tile = CloseTile:new{
                label = def.label,
                tile_w = tile_w,
                tile_h = Screen:scaleBySize(64),
                tap_callback = def.fn,
            }
        else
            tile = Tile:new{
                icon = def.icon,
                label = def.label,
                tile_w = tile_w,
                tile_h = tile_h,
                tap_callback = def.fn,
            }
        end
        self.tile_widgets[#self.tile_widgets + 1] = tile
        row[#row + 1] = tile
    end
    rows[#rows + 1] = row
    if self.hint then
        rows[#rows + 1] = VerticalSpan:new{ width = Screen:scaleBySize(22) }
        rows[#rows + 1] = TextWidget:new{
            text = self.hint,
            face = Font:getFace("cfont", 19),
        }
    end
    self[1] = CenterContainer:new{
        dimen = self.dimen,
        FrameContainer:new{
            background = Blitbuffer.COLOR_WHITE,
            bordersize = Screen:scaleBySize(3),
            padding = Screen:scaleBySize(20),
            VerticalGroup:new{ align = "center", unpack(rows) },
        },
    }
end

----------------------------------------------------------------------
-- Plugin chính
----------------------------------------------------------------------

local BigMenu = WidgetContainer:extend{
    name = "bigmenu",
    is_doc_only = false,
    _patch_checked = false,
}

function BigMenu:init()
    self.ui.menu:registerToMainMenu(self)
    if self.ui.dispatcher then
        self:onDispatcherRegisterActions()
    end
    -- Chế độ Trang chủ (khóa bigmenu_auto_home, mặc định BẬT): ở File
    -- Manager, tự mở bảng ngay khi FM khởi tạo xong. FM được tạo mới
    -- hoàn toàn mỗi lần mở KOReader và mỗi lần thoát sách quay về, nên
    -- bảng hiện như một màn hình chính. Trong Reader không tự mở.
    if self.ui.file_chooser and self.ui.registerPostInitCallback then
        local plugin = self
        self.ui:registerPostInitCallback(function()
            if plugin:isAutoHome() then
                UIManager:nextTick(function()
                    pcall(function() plugin:showHomePanel() end)
                end)
            end
        end)
    end
end

function BigMenu:isAutoHome()
    return G_reader_settings:readSetting("bigmenu_auto_home") ~= false
end

function BigMenu:onDispatcherRegisterActions()
    self.ui.dispatcher:registerAction("bigmenu_home", {
        category = "none",
        event = "ShowBigMenu",
        title = _("Big Menu — bảng biểu tượng"),
        general = true,
    })
end

function BigMenu:onShowBigMenu()
    self:showHomePanel()
    return true
end

-- Kiểm tra patch đi kèm: thiếu hoặc cũ hơn thì (tự) chép bản trong
-- plugin vào thư mục patches/. Gọi một lần khi menu chính được dựng.
function BigMenu:ensurePatch()
    if self._patch_checked then return end
    self._patch_checked = true
    pcall(function()
        local dir = patchesDir()
        local target = dir .. PATCH_NAME
        local current = patchVersionOf(readFile(target))
        if current and not isNewer(BIGMENU_VERSION, current) then
            return -- đã có bản mới nhất
        end
        pcall(function() require("util").makePath(dir) end)
        local f = io.open(target, "wb")
        if not f then return end
        f:write(PATCH_SOURCE)
        f:close()
        UIManager:show(InfoMessage:new{
            text = current
                and _("Đã cập nhật patch Menu To lên " .. BIGMENU_VERSION .. ".\nKhởi động lại KOReader để áp dụng.")
                or _("Đã cài patch Menu To.\nKhởi động lại KOReader để menu to có hiệu lực."),
        })
    end)
end

function BigMenu:addToMainMenu(menu_items)
    self:ensurePatch()
    -- Đặt ở tab "main" (tab cuối, ít mục nhất) và chạm là MỞ BẢNG NGAY —
    -- không chôn trong submenu "More tools" nữa (khó tìm). Cập nhật
    -- OTA làm ngay trong bảng, qua ô "Cập nhật bản mới".
    menu_items.bigmenu = {
        text = _("Big Menu — bảng biểu tượng"),
        sorting_hint = "main",
        callback = function()
            self:showHomePanel()
        end,
    }
end

-- Mở bảng biểu tượng: lưới ô to cho các việc hay dùng nhất.
-- Biểu tượng dùng bộ FontAwesome (vùng mã riêng U+F0xx); KOReader có
-- sẵn font ký hiệu nerdfonts làm font dự phòng nên vẽ được.
function BigMenu:showHomePanel(close_armed)
    local plugin = self
    local panel
    -- act(): đóng bảng rồi mới chạy — dùng cho các ô CHUYỂN MÀN HÌNH.
    local function act(fn)
        return function()
            UIManager:close(panel)
            UIManager:scheduleIn(0.15, fn)
        end
    end
    -- stay(): chạy NGAY trên bảng, bảng vẫn mở — dùng cho các ô dạng
    -- công tắc/hộp thoại, để quay lại là thấy bảng ngay như màn hình chính.
    local function stay(fn)
        return function() pcall(fn) end
    end
    local tiles = {
        { icon = "\239\128\173", label = _("Thư viện sách"), fn = act(function()
            local ui = plugin.ui
            if ui and ui.showFileManager then
                ui:showFileManager()
            elseif ui and ui.file_chooser then
                pcall(function()
                    ui.file_chooser:changeToPath(G_reader_settings:readSetting("home_dir"))
                end)
            end
        end) },
        { icon = "\239\135\154", label = _("Sách đọc gần đây"), fn = act(function()
            UIManager:broadcastEvent(Event:new("ShowHist"))
        end) },
        { icon = "\239\128\138", label = _("Bộ sưu tập"), fn = act(function()
            UIManager:broadcastEvent(Event:new("ShowColl"))
        end) },
        { icon = "\239\128\151", label = _("Đồng hồ"), fn = stay(function()
            -- Mở Sage Clock (nếu đã cài) phủ lên trên bảng; thoát đồng
            -- hồ bằng chạm 2 lần là quay về đúng bảng này.
            UIManager:broadcastEvent(Event:new("ShowSageClock"))
        end) },
        { icon = "\239\131\171", label = _("Đèn nền"), fn = stay(function()
            Device:getPowerDevice():toggleFrontlight()
        end) },
        { icon = "\239\135\171", label = _("Wi-Fi: bật/tắt"), fn = stay(function()
            local NM = require("ui/network/manager")
            if NM:isWifiOn() then NM:toggleWifiOff() else NM:toggleWifiOn() end
        end) },
        { icon = "\239\128\161", label = _("Cập nhật bản mới"), fn = stay(function()
            plugin:checkForUpdate()
        end) },
        { icon = "\239\128\149", label = plugin:isAutoHome()
            and _("Trang chủ: Đang bật") or _("Trang chủ: Đang tắt"), fn = function()
            G_reader_settings:saveSetting("bigmenu_auto_home", not plugin:isAutoHome())
            UIManager:close(panel)
            UIManager:scheduleIn(0.15, function() plugin:showHomePanel() end)
        end },
        { icon = "\239\128\141", plain = true, label = close_armed
            and _("Chạm lần nữa để ĐÓNG") or _("Đóng bảng"), fn = function()
            -- Ô Đóng cũng phải chạm 2 lần (tránh lỡ tay thoát mất home):
            -- lần 1 "lên cò" + vẽ lại bảng với nhãn mới, lần 2 trong
            -- vòng 1,5 giây mới đóng thật.
            local now = nowSeconds()
            if close_armed and plugin._close_armed_at
                and (now - plugin._close_armed_at) <= 1.5 then
                plugin._close_armed_at = nil
                UIManager:close(panel)
            else
                plugin._close_armed_at = now
                UIManager:close(panel)
                UIManager:scheduleIn(0.1, function()
                    plugin:showHomePanel(true)
                end)
            end
        end },
    }
    panel = HomePanel:new{
        tiles = tiles,
        hint = _("Thoát bảng: chạm 2 lần vào nền hoặc ô Đóng"),
    }
    panel.on_exit = function()
        plugin._close_armed_at = nil
        UIManager:close(panel)
    end
    UIManager:show(panel, "full")
end

----------------------------------------------------------------------
-- Tự cập nhật (OTA): tải plugin + patch mới nhất từ GitHub.
-- Chỉ nâng cấp khi bản trên mạng MỚI HƠN; luôn giữ bản sao .bak.
----------------------------------------------------------------------

function BigMenu:checkForUpdate()
    UIManager:show(InfoMessage:new{
        text = _("Đang kiểm tra bản mới…"),
        timeout = 2,
    })
    UIManager:scheduleIn(0.5, function()
        local ok, err = pcall(function()
            local meta = httpGet(OTA_BASE .. "bigmenu.koplugin/_meta.lua")
            if not meta then error("không tải được thông tin phiên bản") end
            local remote = meta:match('version%s*=%s*"([%d%.]+)"')
            if not remote then error("không đọc được phiên bản mới") end
            if remote == BIGMENU_VERSION then
                UIManager:show(InfoMessage:new{
                    text = _("Đã là bản mới nhất (" .. BIGMENU_VERSION .. ")."),
                })
                return
            end
            if not isNewer(remote, BIGMENU_VERSION) then
                UIManager:show(InfoMessage:new{
                    text = _("Bản trên máy (" .. BIGMENU_VERSION .. ") đang mới hơn bản trên mạng (" .. remote .. "). Không cần cập nhật."),
                })
                return
            end
            local main = httpGet(OTA_BASE .. "bigmenu.koplugin/main.lua")
            if not main or #main < 4000 or not main:find("BigMenu", 1, true) then
                error("file plugin tải về không hợp lệ")
            end
            local patch = httpGet(OTA_BASE .. "patches/" .. PATCH_NAME)
            if not patch or not patch:find("BigMenu patch", 1, true) then
                error("file patch tải về không hợp lệ")
            end
            -- Ghi plugin mới (giữ .bak)
            local dir = pluginDir()
            local f = io.open(dir .. "main.lua.new", "wb")
            if not f then error("không ghi được file tạm") end
            f:write(main)
            f:close()
            os.rename(dir .. "main.lua", dir .. "main.lua.bak")
            os.rename(dir .. "main.lua.new", dir .. "main.lua")
            local fm = io.open(dir .. "_meta.lua", "wb")
            if fm then fm:write(meta) fm:close() end
            -- Ghi patch mới vào thư mục patches/
            local pdir = patchesDir()
            pcall(function() require("util").makePath(pdir) end)
            local fp = io.open(pdir .. PATCH_NAME, "wb")
            if fp then fp:write(patch) fp:close() end
            -- Để lần mở menu tới không chép đè bằng bản nhúng cũ
            self._patch_checked = true
            UIManager:show(InfoMessage:new{
                text = _("Đã cập nhật Big Menu lên bản " .. remote .. ".\nHãy khởi động lại KOReader để dùng bản mới."),
            })
        end)
        if not ok then
            UIManager:show(InfoMessage:new{
                text = _("Không cập nhật được. Kiểm tra Wi-Fi rồi thử lại.\n(" .. tostring(err) .. ")"),
            })
        end
    end)
end

return BigMenu
