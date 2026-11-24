### Blobmoji 18, Release 1 Changelog
This is the first release of Blobmoji 18. The new emoji designs are sourced from the latest update to the @googlefonts [noto-emoji repo](https://github.com/googlefonts/noto-emoji) with the exception of the cracked face design (🫫), which uses the same blob style as the other face emojis in this set.

This release also includes updates to some of the existing emojis in the set, courtesy of @Bronnel721.

Additionally, this release includes the following installation fixes, courtesy of @RavioliWonton:

* The installer reads `font_fallback.xml`, `fonts.xml`, and vendor `font_customization.xml`, resolves absolute and relative font paths, and replaces every emoji font the ROM references—in `/system/fonts`, `/system_ext/fonts`, and `/product/fonts`—instead of assuming only `/system/fonts/NotoColorEmoji.ttf`. Installation now fails with a clear error when nothing could be replaced, rather than succeeding silently on ROMs such as ColorOS that load emoji from elsewhere first.
* System-updated emoji fonts under `/data/fonts/files/` (which override module mounts) are removed at install time and again on every boot via `post-fs-data.sh`; other downloaded system fonts are left alone. An optional `block_font_updates` file in the module directory can remount `/data/fonts/files` read-only to block further font updates entirely (see the README).

The `NotoColorEmoji.ttf` file from [here](https://github.com/DavidBerdik/blobmoji2/releases/tag/blobmoji-18r1) was used for this release.
