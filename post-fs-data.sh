#!/system/bin/sh
#
# Runs in post-fs-data, i.e. before system_server starts and therefore before
# FontManagerService reads its font configuration, so everything removed here is
# gone for the whole boot.
#
# Since Android 12 the system can download updated fonts into /data/fonts/files
# (this is how Google delivers new emoji). They take precedence over
# /system/fonts, so the emoji font shipped by this module is ignored while they
# exist. The updater can install them again at any time, which is why this has
# to be repeated on every boot.

MODDIR=${0%/*}
UPDATABLE_DIR=/data/fonts/files

for file in $UPDATABLE_DIR/*/*[Ee]moji*.ttf; do
    [ -f "$file" ] || continue
    dir=${file%/*}
    rm -f "$file"
    # every downloaded font has its own fs-verity signature next to it
    if [ -z "$(find "$dir" -maxdepth 1 -name '*.ttf' 2>/dev/null | head -n 1)" ]; then
        rm -f "$dir/font.fsv_sig"
        rmdir "$dir" 2>/dev/null
    fi
done

# Optional: stop the system font updater from installing fonts again, emoji or
# otherwise. The files that are already there stay readable, new writes fail.
# Enable with: touch /data/adb/modules/blobmoji/block_font_updates
if [ -f "$MODDIR/block_font_updates" ] && [ -d "$UPDATABLE_DIR" ]; then
    if mount -o bind "$UPDATABLE_DIR" "$UPDATABLE_DIR" 2>/dev/null &&
        mount -o remount,ro,bind "$UPDATABLE_DIR" 2>/dev/null; then
        echo "Blobmoji: font updates are blocked ($UPDATABLE_DIR is read-only)"
    else
        echo "Blobmoji: could not make $UPDATABLE_DIR read-only, font updates are NOT blocked"
    fi
fi
