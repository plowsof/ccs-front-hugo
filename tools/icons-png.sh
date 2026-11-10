#!/usr/bin/env bash
# icons-png.sh: make the site's icons as PNGs from tools/icons.svg.
# The site ships no SVG, since Tor Browser at "Safest" doesn't draw it.
# Each icon comes at 1x, 2x and 3x. The browser picks the one its screen needs.
# Line icons are black on transparent, used as CSS masks to take the text's colour.
# Run it after changing tools/icons.svg, with Chrome or Chromium, pngquant and oxipng.
# Commit the output. Only the person changing the icons runs this, never the build.
# PNG, not WebP or AVIF: it is nearly as small at these sizes, and every browser draws it.
set -euo pipefail
here=$(dirname "$(readlink -f "$0")")
out=$here/../assets/assets/icons
chrome=$(command -v google-chrome chromium chromium-browser | head -n 1)
command -v pngquant oxipng > /dev/null || { echo "icons-png.sh: needs pngquant and oxipng" >&2; exit 1; }
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
rm -rf "$out" && mkdir -p "$out"
render() {   # render SVG_FILE PX PNG
    "$chrome" --headless=new --disable-gpu --hide-scrollbars --default-background-color=00000000 \
        --window-size="$2,$2" --screenshot="$3" "file://$1" > /dev/null 2>&1
}
# One SVG file per <symbol>. Each <symbol> and </symbol> is on its own line.
awk -v dir="$tmp" '
    /<symbol / {
        match($0, /id="[^"]+"/); name = substr($0, RSTART + 4, RLENGTH - 5)
        attrs = $0; sub(/.*<symbol id="[^"]+"/, "", attrs); sub(/>[[:space:]]*$/, "", attrs)
        gsub(/currentColor/, "#000", attrs)
        f = dir "/" name ".svg"
        printf "<svg xmlns=\"http://www.w3.org/2000/svg\" width=\"100%%\" height=\"100%%\"%s>", attrs > f
        next
    }
    /<\/symbol>/ { if (f) { print "</svg>" > f; close(f); f = "" }; next }
    f { print > f }
' "$here/icons.svg"
for f in "$tmp"/*.svg; do
    name=$(basename "$f" .svg)
    base=32; [[ $name == logo ]] && base=28
    for x in 1 2 3; do render "$f" $((base * x)) "$out/$name-${x}x.png"; done
done
render "$tmp/logo.svg" 32 "$out/favicon-32.png"
render "$tmp/logo.svg" 180 "$out/favicon-180.png"
# The logo and the Tor onion get a 256-colour palette, kept only when smaller.
pngquant --speed 1 --nofs --strip --skip-if-larger --force --ext .png 256 \
    "$out"/logo-*.png "$out"/favicon-*.png "$out"/tor-*.png || [[ $? == 98 || $? == 99 ]]
# Then every icon compressed losslessly. Line icons become grey plus transparency.
oxipng -q -o max --strip safe --alpha "$out"/*.png
du -cb "$out"/*.png | tail -n 1
