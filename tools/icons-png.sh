#!/usr/bin/env bash
# icons-png.sh: the site's icons as PNGs, from tools/icons.svg (Lucide, and the Monero logo). The
# site ships no SVG: Tor Browser at "Safest" doesn't draw it. Each icon at 1x, 2x and 3x, the
# browser takes the sharpest its screen needs (image-set, srcset). The line icons are black on
# transparent, used as CSS masks so they keep the text's colour; the logo and the Tor onion keep
# their own.
# Run it after changing tools/icons.svg, with Chrome or Chromium and Python's Pillow; commit what
# it writes. (PNG rather than WebP or AVIF: optimised, it is nearly as small for icons this size,
# and every browser draws it, Tor Browser at any level included.)
set -euo pipefail
here=$(dirname "$(readlink -f "$0")")
out=$here/../assets/assets/icons
chrome=$(command -v google-chrome chromium chromium-browser | head -n 1)
tmp=$(mktemp -d)
trap 'rm -rf "$tmp"' EXIT
rm -rf "$out" && mkdir -p "$out"
render() {   # render SVG_FILE PX PNG
    "$chrome" --headless=new --disable-gpu --hide-scrollbars --default-background-color=00000000 \
        --window-size="$2,$2" --screenshot="$3" "file://$1" > /dev/null 2>&1
}
python3 - "$here/icons.svg" "$tmp" <<'PY'
import re, sys
src = open(sys.argv[1]).read()
for name, attrs, body in re.findall(r'<symbol id="([^"]+)"([^>]*)>(.*?)</symbol>', src, re.S):
    attrs = attrs.replace('currentColor', '#000')
    open(f"{sys.argv[2]}/{name}.svg", "w").write(
        f'<svg xmlns="http://www.w3.org/2000/svg" width="100%" height="100%"{attrs}>{body}</svg>')
PY
for f in "$tmp"/*.svg; do
    name=$(basename "$f" .svg)
    base=32; [[ $name == logo ]] && base=28
    for x in 1 2 3; do render "$f" $((base * x)) "$out/$name-${x}x.png"; done
done
render "$tmp/logo.svg" 32 "$out/favicon-32.png"
render "$tmp/logo.svg" 180 "$out/favicon-180.png"
# smallest PNGs: the line icons as black plus transparency only (a mask uses just that)
python3 - "$out" <<'PY'
import glob, sys
from PIL import Image
for f in glob.glob(sys.argv[1] + "/*.png"):
    im = Image.open(f)
    if "/logo-" not in f and "/favicon-" not in f and "/tor-" not in f:
        im = Image.merge("LA", (Image.new("L", im.size, 0), im.getchannel("A")))
    im.save(f, "PNG", optimize=True)
PY
du -cb "$out"/*.png | tail -n 1
