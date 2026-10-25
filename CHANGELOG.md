# Changelog

All notable changes to KOReader Big Menu are documented in this file.
The format is based on Keep a Changelog, and this project adheres to
Semantic Versioning.

## [1.0.0] — 2026-10-25

First public release. Split out of the Sage Clock project after the
icon panel proved useful enough to deserve its own home.

### Added
- **Icon home panel** (`bigmenu.koplugin`): a full-screen 2-column
  grid of large tiles — Library, Recently read, Collections,
  Frontlight toggle, Wi-Fi toggle, OTA update, Close — each with a
  big FontAwesome glyph and a bold label. Opens from the Tools menu
  or from any screen via a bindable Dispatcher action
  (`ShowBigMenu`, e.g. on a corner long-press).
- **Menu enlargement patch** (`patches/2-bigmenu.lua`): a standard
  KOReader user patch that enlarges the whole KOReader menu system —
  TouchMenu row height 50→68, menu text 22→28, tab labels 20→25,
  UI text 24→27, 8 items per page, library list font 26 via KOReader's
  own `items_per_page` / `items_font_size` settings. Every step is
  `pcall`-guarded so future KOReader changes degrade gracefully.
- **Patch auto-install**: the plugin embeds a byte-identical copy of
  the patch and writes it to `koreader/patches/` on first run (or
  when its version is newer), so a first install is a single folder
  copy.
- **OTA self-update** for both plugin and patch: numeric semantic
  version comparison (upgrade only, never downgrade), download
  validation (size + marker strings), `main.lua.bak` backup before
  swapping, and a restart prompt afterwards.
