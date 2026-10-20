#!/usr/bin/env bash
# Convierte una imagen PNG/JPG en una fuente con UN solo icono, para usarlo en polybar.
# Uso: mkicon.sh logo.png [--invertir]
#   --invertir  úsalo si tu logo es CLARO sobre fondo oscuro/transparente
set -euo pipefail

IMG="${1:?Uso: mkicon.sh imagen.png [--invertir]}"
INV="${2:-}"
OUT="$HOME/.local/share/fonts/HunterIcon.ttf"
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT

command -v potrace   >/dev/null || { echo "Falta potrace:   sudo apt install potrace"; exit 1; }
command -v fontforge >/dev/null || { echo "Falta fontforge: sudo apt install fontforge python3-fontforge"; exit 1; }
command -v convert   >/dev/null || { echo "Falta imagemagick: sudo apt install imagemagick"; exit 1; }

# 1) imagen -> mapa de bits blanco/negro (potrace traza lo NEGRO)
#    Si el logo es claro (--invertir), el fondo transparente se rellena de negro y luego se invierte.
if [[ "$INV" == "--invertir" ]]; then
  convert "$IMG" -background black -alpha remove -alpha off -colorspace Gray -threshold 50% -negate "$TMP/logo.pbm"
else
  convert "$IMG" -background white -alpha remove -alpha off -colorspace Gray -threshold 50% "$TMP/logo.pbm"
fi

# 2) mapa de bits -> vector SVG
potrace -s "$TMP/logo.pbm" -o "$TMP/logo.svg"

# 3) vector -> fuente con un glifo en U+E900
mkdir -p "$(dirname "$OUT")"
cat > "$TMP/make.py" << PYEOF
import fontforge, psMat
f = fontforge.font()
f.encoding = 'UnicodeFull'
f.em = 1000; f.ascent = 800; f.descent = 200
f.fontname = 'HunterIcon'; f.familyname = 'HunterIcon'; f.fullname = 'HunterIcon'
g = f.createChar(0xE900, 'hunter')
g.importOutlines('$TMP/logo.svg')
x0, y0, x1, y1 = g.boundingBox()
s = 800.0 / (y1 - y0)                        # alto final = 800 unidades
g.transform(psMat.scale(s))
x0, y0, x1, y1 = g.boundingBox()
g.transform(psMat.translate(-x0 + 40, -y0))  # apoyado en la línea base
g.width = int(x1 - x0) + 80
f.generate('$OUT')
PYEOF
fontforge -lang=py -script "$TMP/make.py" >/dev/null 2>&1 || true
[[ -f "$OUT" ]] || { echo "Error: no se generó la fuente"; exit 1; }
fc-cache -f
echo "Listo: $OUT"
echo "Glifo en U+E900 (en UTF-8: ee a4 80)"
