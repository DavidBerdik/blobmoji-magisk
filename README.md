# Blobmoji for Magisk

![Noto Emoji with Blobs enabled](noto.png)

This repository is intended to continue the development of the Blob emojis which have been abandoned by the original creators in 2017.

My goal is to upgrade the Blob emojis with a fresh style which is consistent to other emoji vendors.

Another thing is that this emoji set includes some emojis and ZWJ-sequences which are not part of the current emoji standard (although some or most of them are about to be included in the upcoming Unicode-standard), which means it might be one of the biggest emoji sets currently available!

NotoColorEmoji fonts are provided by [C1710's project](https://github.com/C1710/blobmoji).

Most information on this fork will be included in the [Wiki](https://github.com/C1710/blobmoji/wiki). There you'll find more detailed build instructions and other helpful information on how to use this font and much more.
If you want to use this font - there's a [Wiki page](https://github.com/C1710/blobmoji/wiki/Installation-Usage) :D

## NOTICE

* You should use latest Magisk Manager to install this module. If you meet any problem under installation from Magisk Manager, please try to install it from recovery.
* Recent fixes:
Update project structure.

## How the module works

`customize.sh` reads the font configuration of the running ROM
(`/system/etc/font_fallback.xml`, `/system/etc/fonts.xml` and the vendor
`font_customization.xml` files), collects every font referenced by the
`und-Zsye` (emoji) families, and replaces it with Blobmoji in the matching
partition (`/system/fonts`, `/system_ext/fonts`, `/product/fonts`). Files in
those directories whose name contains `Emoji` are replaced as well, and the
installation fails loudly when nothing could be replaced.

This is required because font fallback uses the *first* family that contains the
glyph, and ROMs such as ColorOS declare their own emoji font before
`NotoColorEmoji.ttf`:

```xml
<family lang="und-Zsye">
  <font weight="400" style="normal" postScriptName="ColorUniEmoji">../../product/fonts/ColorUniEmoji.ttf</font>
</family>
```

Replacing only `/system/fonts/NotoColorEmoji.ttf` has no visible effect there.
Since Android 15 the runtime configuration is `font_fallback.xml`, as `fonts.xml`
is deprecated.

### System updated fonts

Since Android 12 the system can update fonts at runtime, which is how Google
delivers new emoji. Those files are stored in `/data/fonts/files/<hash>/` and
take precedence over `/system/fonts`, so no module mount can override them. The
installer therefore removes the updated emoji fonts, and `post-fs-data.sh`
repeats that on every boot, because the updater can install them again at any
time.

An update that arrives while the device is running can still take effect until
the next reboot. To block the updater completely, create an empty file:

```sh
touch /data/adb/modules/blobmoji/block_font_updates
```

`post-fs-data.sh` then remounts `/data/fonts/files` read-only on every boot: the
fonts that are already installed stay readable, new updates fail. This also
blocks updates of other system fonts (for example Google Sans), which is why it
is opt-in.

## Credit & Support

* Copyright (C) 2018-2020 simonsmh
* Any issue or pull request is welcomed.
* Star this module at [GitHub](https://github.com/Magisk-Modules-Repo/blobmoji).
