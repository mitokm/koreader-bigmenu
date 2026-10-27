# Changelog

All notable changes to KOReader Big Menu are documented in this file.
The format is based on Keep a Changelog, and this project adheres to
Semantic Versioning.

## [1.0.6] \u2014 2026-10-27

### Fixed
- **Tile labels overflowed their tiles in landscape** (e.g.
  \u201cS\u00e1ch \u0111\u1ecdc g\u1ea7n \u0111\u00e2y\u201d bled into the
  neighbouring tiles): labels are now drawn with a fixed-width text
  box, so a long label **wraps to a second line inside its tile**
  instead of spilling out. Landscape tiles also got a bit more room
  (narrower gaps, taller tiles) and a slightly smaller label font.

## [1.0.5] \u2014 2026-10-26

### Fixed
- **Rotation**: the panel kept its portrait layout after rotating to
  landscape, so the bottom rows were cut off. The panel now rebuilds
  its grid whenever the screen rotates: 4 columns with shorter tiles
  in landscape, the familiar 2 columns in portrait \u2014 everything
  stays on screen in both orientations.

## [1.0.4] \u2014 2026-10-26

### Changed
- **Close is now a small frameless button** (\u2715 + label in a row,
  about a third of a tile's height, no border box) instead of a full
  tile \u2014 first on-device styling feedback.
- The tile grid sits a little lower under the title, so the panel
  reads more balanced.

## [1.0.3] \u2014 2026-10-26

### Added
- **Clock tile**: opens the Sage Clock screensaver (if that plugin is
  installed) on top of the panel \u2014 exiting the clock with its
  double-tap lands you right back on the panel.

### Changed
- **Leaving the panel now takes a double-tap**, like the Sage Clock:
  double-tap the panel background, or tap the Close tile twice (the
  first tap arms it and relabels it). A single stray tap can no
  longer dismiss your home screen.

## [1.0.2] \u2014 2026-10-26

### Added
- **Home mode** (setting `bigmenu_auto_home`, ON by default): the
  panel opens by itself whenever the File Manager appears \u2014 at
  KOReader start and every time you close a book and come back \u2014
  so it works like a home screen. Toggle it with the new
  *Trang ch\u1ee7 (Home)* tile on the panel.

### Changed
- Switch/dialogue tiles (Frontlight, Wi-Fi, Update) no longer close
  the panel: they act on top of it, and closing their dialogue
  returns you to the panel. Navigation tiles still close the panel
  and go where you tapped.

## [1.0.1] \u2014 2026-10-26

### Fixed
- **Panel layout overflow on 300 dpi devices**: icon and label sizes
  were passed through `Screen:scaleBySize()` *and* scaled again inside
  `Font:getFace()`, so tiles rendered roughly double size and
  overlapped (first on-device report, Kobo Sage). Sizes are now raw
  values, as `Font:getFace()` expects; grid width and frame padding
  rebalanced to fit the screen.

### Changed
- **The menu entry moved**: it now sits in the **main** menu tab and
  opens the panel with a single tap, instead of being buried in the
  *Tools \u2192 More tools* submenu. OTA update lives on the panel's
  Update tile.

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
