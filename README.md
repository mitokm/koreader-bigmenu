# KOReader Big Menu — big icon panel & enlarged menus for e-ink readers

![Version](https://img.shields.io/badge/version-1.0.1-blue.svg)
![License](https://img.shields.io/badge/license-MIT-green.svg)
![Platform](https://img.shields.io/badge/platform-KOReader-lightgrey.svg)
![Language](https://img.shields.io/badge/UI-Vietnamese%20%2B%20gettext-orange.svg)

**Đọc bản tiếng Việt: [README.vi.md](README.vi.md)** · **Detailed installation: [INSTALL.md](INSTALL.md)**

KOReader is powerful, but its menus were designed for precision tapping:
small text, short rows, deep hierarchies. On an e-ink screen — slow
refresh, no hover, big fingers — navigating them is genuinely painful.

**Big Menu** fixes that in two complementary ways:

1. **An icon home panel** — a full-screen grid of large tiles
   (Library, Recently read, Collections, Frontlight, Wi-Fi, Update)
   with a big symbol and a big label on every tile. One tap per action,
   no menu diving.
2. **A global menu enlargement patch** — a standard KOReader
   *user patch* that makes **every** built-in menu bigger: taller rows,
   larger text, fewer items per page, larger list fonts — so the menus
   you still need are at least easy to hit.

Both parts **update over the air (OTA)** from this repository: after the
one-time install you never plug in a USB cable again — not even to fix
a font size.

![Home panel](docs/homepanel-preview.png)

---

## What you get

| Part | What it does | Where it lives on the device |
|---|---|---|
| `bigmenu.koplugin` | Icon home panel, auto-installs the patch, OTA updater | `.adds/koreader/plugins/bigmenu.koplugin/` |
| `patches/2-bigmenu.lua` | Enlarges all KOReader menus system-wide | `.adds/koreader/patches/2-bigmenu.lua` |

You only have to copy **one** of them: install the plugin and it will
write the patch for you on first run (see [How it works](#how-it-works)).

## The enlargement, in numbers

All values are KOReader source defaults vs. what the patch sets.
Sizes are logical units passed through `Screen:scaleBySize()`, so they
scale correctly with each device's DPI.

| Element | KOReader default | Big Menu | Where |
|---|---|---|---|
| Main menu row height (`Size.item.height_large`) | 50 | **68** | TouchMenu (all top menus) |
| Menu item text (`smallinfofont`) | 22 | **28** | TouchMenu items |
| Menu tab labels (`ffont`) | 20 | **25** | TouchMenu tab bar |
| General UI text / buttons (`cfont`) | 24 | **27** | Dialogs, buttons, this panel |
| Titles (`tfont`) | 26 | **28** | Dialog titles |
| Menu items per page (`max_per_page_default`) | 10 | **8** | TouchMenu paging |
| List items per page (`items_per_page` setting) | auto | **8** | Library, History, Collections lists |
| List font size (`items_font_size` setting) | auto (≤24) | **26** | Same lists |

## How it works

### The icon panel (`bigmenu.koplugin`)

A regular KOReader plugin (single `main.lua`, no dependencies beyond
KOReader itself). It registers:

- a **Tools menu** entry *“Big Menu — bảng biểu tượng”* with
  *Open icon panel*, *Update (OTA)* and a version row;
- a **Dispatcher action** *“Big Menu — bảng biểu tượng”*
  (event `ShowBigMenu`) — bind it to any gesture (for example a corner
  tap or a long press) in KOReader's gesture settings and the panel
  opens from anywhere, even mid-book, with zero menu navigation.

Each tile is an `InputContainer` with its own tap range, a framed
`60`-unit FontAwesome glyph (KOReader ships the Nerd Fonts symbol font
as a text fallback, so the glyphs render without shipping any icon
files) and a bold `30`-unit label. Tile actions use public KOReader
behaviour only: `ReaderUI:showFileManager()`, the `ShowHist` /
`ShowColl` broadcast events, `Device:getPowerDevice():toggleFrontlight()`
and `NetworkManager:toggleWifiOn/Off()` — each wrapped in `pcall` so a
KOReader API change degrades one tile instead of breaking the panel.

### The patch (`patches/2-bigmenu.lua`)

KOReader officially supports *user patches*: Lua files in
`koreader/patches/` that run at startup. A `2-` prefixed patch runs
after settings are available. The patch:

1. raises entries in `Font.sizemap` (the named-font size table read by
   `Font:getFace()`);
2. raises `Size.item.height_*` and overrides `TouchMenu.item_height` /
   `TouchMenu.max_per_page_default` on the class, so every menu created
   afterwards inherits the bigger geometry;
3. writes KOReader's own supported settings `items_per_page` and
   `items_font_size`, which `Menu` widgets (library, history,
   collections) read at init.

Every step is individually wrapped in `pcall`: if a future KOReader
release renames an internal, that step is skipped silently instead of
breaking startup. Removing the file and restarting restores stock
KOReader completely (the two list settings can be deleted from
`settings.reader.lua`, after which KOReader computes them
automatically again).

### Who updates the patch? The plugin does.

The patch text is embedded in the plugin (byte-identical to
`patches/2-bigmenu.lua` in this repo — the build script injects it).
When KOReader's main menu is first built after install, the plugin
compares the version header of `patches/2-bigmenu.lua` on the device
with its own and writes the newer one if needed, then asks for a
restart. The OTA updater (below) downloads a fresh patch together with
the plugin, so the two never drift apart.

### OTA updates

*Open the plugin menu → “Cập nhật bản mới (OTA, cần Wi-Fi)”*, or tap
the panel's **Update** tile. The updater:

1. fetches `bigmenu.koplugin/_meta.lua` from this repo's `main` branch
   and parses the remote version;
2. compares versions numerically (semantic `x.y.z`) and **only
   upgrades** — it refuses to "update" to an older or equal version, so
   a device running ahead of the repo is never downgraded;
3. downloads `main.lua` and `patches/2-bigmenu.lua`, validating size
   and marker strings before touching anything on the device;
4. swaps files in with `main.lua.bak` kept as a backup, writes the new
   `_meta.lua` and the new patch, and tells you to restart KOReader.

No computer, no cable, no file manager gymnastics on the device.

## Installation

Short version (full step-by-step in [INSTALL.md](INSTALL.md)):

1. Copy the folder **`bigmenu.koplugin`** into
   `.adds/koreader/plugins/` on the reader.
2. Restart KOReader and open the Tools menu once — the plugin writes
   `patches/2-bigmenu.lua` by itself and confirms with a message.
3. Restart KOReader once more. Done: menus are big, and the icon panel
   is under *Tools → Big Menu* (bind a gesture to it for one-tap
   access).

Alternatively copy `patches/2-bigmenu.lua` manually too — useful if
you only want the enlargement without the panel.

## Configuration

There are no settings screens; the enlargement values are constants
chosen for an 8″ 300 dpi reader (Kobo Sage). To tune them, edit
`patches/2-bigmenu.lua` (or ask for a new release — values are just
numbers in three small blocks at the top of the file):

| Knob | Block | Effect |
|---|---|---|
| `Font.sizemap.*` values | 1 | Text sizes for menu items, tabs, dialogs, titles |
| `Size.item.height_*`, `TouchMenu.item_height` | 2 | Menu row heights |
| `TouchMenu.max_per_page_default` | 2 | Menu items per page (fewer = taller rows) |
| `items_per_page`, `items_font_size` | 3 | Book list density and font |

Because the plugin re-writes the patch when its embedded copy is
newer, manual patch edits survive until the next plugin release —
bump the version header in your edited patch if you want your tweak
to stick across OTA updates of the same plugin version.

## Known limitations

- The icon glyphs rely on KOReader's bundled Nerd Fonts fallback
  (`nerdfonts/symbols.ttf`). On builds without it, tiles still work —
  the label carries the meaning — but the symbol may render as an
  empty box.
- The patch enlarges menus KOReader builds **after** startup; it does
  not change book typography or the reading menus' content layout
  beyond the global font sizes above.
- OTA needs the reader's Wi-Fi on and GitHub reachable; there is no
  background/scheduled update check — updating is one deliberate tap.
- The two list settings (`items_per_page`, `items_font_size`) are
  written into KOReader's own settings; deleting the patch does not
  remove them (delete the keys, or leave them — they are ordinary
  KOReader settings).

## Troubleshooting

| Symptom | Likely cause & fix |
|---|---|
| No **Big Menu** entry in the Tools menu | KOReader was not fully restarted after copying, or the folder is misplaced — the path must be `.adds/koreader/plugins/bigmenu.koplugin/main.lua` |
| Panel opens but menus are still small | The patch has not been written or KOReader not restarted since — open the Tools menu once, wait for the confirmation message, restart KOReader, and check `patches/2-bigmenu.lua` exists |
| A tile does nothing | That KOReader build changed an internal API; the tile fails silently by design (`pcall`). Open an issue with your KOReader version |
| Icons show as empty boxes | Build lacks the Nerd Fonts fallback font — labels still identify every tile |
| OTA says “cannot update” | Wi-Fi off, GitHub unreachable, or the download failed validation — check Wi-Fi and retry |
| Menus too big / too small now | Edit the constants in `patches/2-bigmenu.lua` (see Configuration), or delete the patch to return to stock |

## Development

- `bigmenu.koplugin/main.lua` is **generated**: edit
  `plugin_template.lua` in the project workspace, keep
  `patches/2-bigmenu.lua` as the single source of the patch text, and
  run the build step that injects the patch into the template
  placeholder `__PATCH_SOURCE__`.
- Syntax-check everything with a Lua parser before release
  (`luaparser` / LuaJIT `luajit -bl` — KOReader runs LuaJIT).
- Versioning is semantic; the version lives in three places that must
  agree: `BIGMENU_VERSION` in `main.lua`, `version` in `_meta.lua`,
  and the patch header line `-- BigMenu patch | version: x.y.z`.

## Status & version

- **Version 1.0.0** — first public release (see
  [CHANGELOG.md](CHANGELOG.md)).
- Developed and tested on a **Kobo Sage** (8″, 1440×1920, 300 ppi)
  running KOReader; the mechanisms used (user patches, named font
  sizes, `Size` geometry, Dispatcher actions) are device-independent.

## License

MIT — see [LICENSE](LICENSE).
