# Blobmoji for Magisk / KernelSU
#
# Replaces every emoji font that the system's font configuration actually
# references. Assuming the AOSP layout and only overwriting
# /system/fonts/NotoColorEmoji.ttf has no visible effect when:
#   * the ROM declares its own emoji font before NotoColorEmoji.ttf, e.g. ColorOS
#     <family lang="und-Zsye">
#       <font weight="400" style="normal" postScriptName="ColorUniEmoji">../../product/fonts/ColorUniEmoji.ttf</font>
#     </family>
#     (the first family containing a glyph wins),
#   * the emoji font lives in /product/fonts or /system_ext/fonts,
#   * the emoji family is only declared in font_fallback.xml, which is the
#     runtime configuration since Android 15 (fonts.xml is deprecated), or
#   * the font entry carries extra attributes, which the previous sed pattern
#     did not match.

MIRRORPATH=
[ -d /sbin/.magisk/mirror ] && MIRRORPATH=/sbin/.magisk/mirror

FONT_SRC=$MODPATH/system/fonts/Blobmoji.ttf
FONT_CONFS="/system/etc/font_fallback.xml /system/etc/fonts.xml /system/etc/font_customization.xml /system/etc/fonts_customization.xml /system_ext/etc/fonts_customization.xml /product/etc/font_customization.xml"
FONT_DIRS="/system/fonts /system_ext/fonts /product/fonts"
TARGETS=

ui_print "- Blobmoji: looking for emoji font definitions"

# Turn a reference from fonts.xml into an absolute path. Font files are either
# bare names (looked up in the font directories) or paths relative to
# /system/etc, e.g. ../../product/fonts/ColorUniEmoji.ttf
resolve_font_path() {
    path=$1
    case "$path" in
        /*) printf '%s\n' "$path"; return 0 ;;
    esac
    base=/system/etc
    while [ "${path#../}" != "$path" ]; do
        base=${base%/*}
        path=${path#../}
    done
    path=${path#./}
    case "$path" in
        "")
            return 1 ;;
        */*)
            printf '%s/%s\n' "${base%/}" "$path" ;;
        *)
            printf '/system/fonts/%s\n' "$path" ;;
    esac
}

# Print every font file referenced by the "und-Zsye" (emoji) families.
extract_emoji_fonts() {
    [ -f "$1" ] || return 0
    awk '
        function trim(s) { gsub(/^[ \t]+/, "", s); gsub(/[ \t]+$/, "", s); return s }
        {
            line = $0
            sub(/\r$/, "", line)
            if (line ~ /<family/) {
                infamily = (line ~ /lang="und-Zsye"/ && line !~ /ignore="true"/)
                pending = 0
                if (line ~ /<\/family>/) infamily = 0
                next
            }
            if (!infamily) next
            if (line ~ /<\/family>/) { infamily = 0; pending = 0; next }
            if (line ~ /<font/) {
                pending = 0
                rest = line
                sub(/^[^>]*>/, "", rest)
                if (rest ~ /<\/font>/) sub(/<\/font>.*/, "", rest)
                else if (trim(rest) == "") { pending = 1; next }
                value = trim(rest)
                if (value != "") print value
                next
            }
            if (pending) {
                value = trim(line)
                if (value != "") { print value; pending = 0 }
            }
        }
    ' "$1"
}

# Register a device path as a replacement target, ignoring duplicates, missing
# files and paths outside the font directories.
add_target() {
    case "$1" in
        */fonts/*) ;;
        *) return 0 ;;
    esac
    [ -f "$1" ] || return 0
    case " $TARGETS " in
        *" $1 "*) return 0 ;;
    esac
    TARGETS="$TARGETS $1"
}

# /system/fonts/x -> $MODPATH/system/fonts/x
# /product/fonts/x -> $MODPATH/system/product/fonts/x
module_path() {
    case "$1" in
        /system/*)  printf '%s\n' "$MODPATH/system/${1#/system/}" ;;
        /product/*|/system_ext/*|/vendor/*|/odm/*)
                    printf '%s\n' "$MODPATH/system/${1#/}" ;;
        *)          printf '\n' ;;
    esac
}

for conf in $FONT_CONFS; do
    for ref in $(extract_emoji_fonts "$MIRRORPATH$conf"); do
        add_target "$(resolve_font_path "$ref")"
    done
done

# Safety net: catch emoji fonts the configuration above did not mention.
for dir in $FONT_DIRS; do
    for file in "$dir"/*[Ee]moji*.ttf "$dir"/*[Ee]moji*.otf; do
        [ -f "$file" ] && add_target "$file"
    done
done

REPLACED=0
for target in $TARGETS; do
    dest=$(module_path "$target")
    if [ -z "$dest" ]; then
        ui_print "! Cannot replace $target (unsupported partition), skipping"
        continue
    fi
    mkdir -p "$(dirname "$dest")"
    cp -f "$FONT_SRC" "$dest"
    set_perm "$dest" 0 0 0644
    ui_print "- Replacing $target"
    REPLACED=$((REPLACED + 1))
done

if [ "$REPLACED" = 0 ]; then
    ui_print "*********************************************************"
    ui_print "! No emoji font found on this device, nothing was replaced"
    ui_print "! Please report your ROM at"
    ui_print "! https://github.com/DavidBerdik/blobmoji-magisk/issues"
    abort   "*********************************************************"
fi

# Since Android 12 the system can update fonts at runtime (this is how Google
# delivers new emoji). Those files live in /data/fonts/files, take precedence
# over /system/fonts and cannot be overridden by a module mount, so delete them.
# post-fs-data.sh repeats this on every boot, as the updater can install them
# again at any time.
for file in /data/fonts/files/*/*[Ee]moji*.ttf; do
    [ -f "$file" ] || continue
    dir=$(dirname "$file")
    ui_print "- Removing system updated emoji font ${file#/data/fonts/files/}"
    rm -f "$file"
    # every downloaded font has its own fs-verity signature next to it
    if [ -z "$(find "$dir" -maxdepth 1 -name '*.ttf' 2>/dev/null | head -n 1)" ]; then
        rm -f "$dir/font.fsv_sig"
        rmdir "$dir" 2>/dev/null
    fi
done

# make sure the boot script is executable, whatever the zip stored
[ -f "$MODPATH/post-fs-data.sh" ] && chmod 0755 "$MODPATH/post-fs-data.sh"

rm -f $MODPATH/LICENSE* 2>/dev/null
