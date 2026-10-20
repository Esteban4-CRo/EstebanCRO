#!/usr/bin/env bash
# wsapps.sh - muestra en polybar los escritorios de bspwm con las apps abiertas en cada uno.
# Se refresca solo cuando bspwm avisa de un cambio (polybar: tail = true).

COLOR_FOCO="#ff1a3c"     # escritorio activo
COLOR_OCUPADO="#ffffff"  # escritorio con apps
COLOR_VACIO="#6b7785"    # escritorio vacío (solo si MOSTRAR_VACIOS=1)
MOSTRAR_VACIOS=0         # 1 = mostrar también los escritorios vacíos como un punto

# Icono según la clase de la ventana. Si no hay icono, muestra el nombre.
icono() {
  case "${1,,}" in
    kitty|alacritty|xterm|qterminal|xfce4-terminal) printf '\xef\x84\xa0' ;;  # terminal
    firefox*)                                       printf '\xef\x89\xa9' ;;  # firefox
    chromium*|google-chrome*)                       printf '\xef\x89\xa8' ;;  # chrome
    thunar|pcmanfm|nautilus|dolphin)                printf '\xef\x81\xbb' ;;  # carpeta
    code|code-oss|codium)                           printf '\xef\x84\xa1' ;;  # código
    *burp*)                                         printf '\xef\x84\xb2' ;;  # escudo
    wireshark)                                      printf '\xef\x87\xab' ;;  # red
    "")                                             printf '?' ;;
    *)                                              printf '%s' "${1,,}" ;;
  esac
}

render() {
  local focused desk apps win cls out=""
  focused=$(bspc query -D -d focused)

  for desk in $(bspc query -D); do
    apps=""
    for win in $(bspc query -N -n .window -d "$desk"); do
      cls=$(bspc query -T -n "$win" | grep -o '"className":"[^"]*"' | cut -d'"' -f4)
      apps+="$(icono "$cls") "
    done
    apps="${apps% }"

    if [[ "$desk" == "$focused" ]]; then
      out+="%{F$COLOR_FOCO}${apps:-●}%{F-}   "
    elif [[ -n "$apps" ]]; then
      out+="%{F$COLOR_OCUPADO}${apps}%{F-}   "
    elif [[ "$MOSTRAR_VACIOS" == "1" ]]; then
      out+="%{F$COLOR_VACIO}·%{F-}   "
    fi
  done

  echo "${out%   }"
}

render
bspc subscribe desktop_focus desktop_add desktop_remove \
               node_add node_remove node_transfer | while read -r _; do
  render
done

