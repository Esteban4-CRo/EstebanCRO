#!/usr/bin/env bash
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP="$HOME/.config-backups/$(date +%Y%m%d-%H%M%S)"

if [[ $EUID -eq 0 ]]; then
  echo "No ejecutes este script como root." >&2
  exit 1
fi

if ! grep -qi kali /etc/os-release; then
  echo "Este script está pensado para Kali Linux." >&2
  read -rp "¿Continuar de todos modos? [s/N] " r
  [[ "$r" =~ ^[sS]$ ]] || exit 1
fi

copiar() {
  local origen=$1 destino=$2
  if [[ -e "$destino" || -L "$destino" ]]; then
    mkdir -p "$BACKUP"
    mv "$destino" "$BACKUP/$(basename "$destino")"
  fi
  mkdir -p "$(dirname "$destino")"
  cp -r "$origen" "$destino"
}

echo "[1/5] Instalando paquetes..."
sudo apt update
grep -v '^\s*#' "$REPO/packages.txt" | xargs sudo apt install -y
if [[ "$(systemd-detect-virt 2>/dev/null || true)" == "vmware" ]]; then
  sudo apt install -y open-vm-tools-desktop
fi

echo "[2/5] Copiando configuraciones..."
for dir in "$REPO"/config/*/; do
  copiar "${dir%/}" "$HOME/.config/$(basename "$dir")"
done
[[ -f "$REPO/zsh/.zshrc" ]] && copiar "$REPO/zsh/.zshrc" "$HOME/.zshrc"
[[ -f "$REPO/zsh/.p10k.zsh" ]] && copiar "$REPO/zsh/.p10k.zsh" "$HOME/.p10k.zsh"
mkdir -p "$HOME/.config/bin"
touch "$HOME/.config/bin/target"

echo "[3/5] Instalando scripts..."
mkdir -p "$HOME/.local/bin"
for s in "$REPO"/scripts/*; do
  install -m 755 "$s" "$HOME/.local/bin/$(basename "$s")"
done
if [[ -f "$REPO/scripts/settarget" ]]; then
  sudo install -m 755 "$REPO/scripts/settarget" /usr/local/bin/settarget
fi
chmod +x "$HOME"/.config/polybar/launch.sh "$HOME"/.config/polybar/scripts/* "$HOME"/.config/bin/* 2>/dev/null || true

echo "[4/5] Fuentes..."
mkdir -p "$HOME/.local/share/fonts"
for par in "Iosevka|Iosevka Nerd" "Hermit|Hurmit Nerd"; do
  zip=${par%%|*}
  familia=${par##*|}
  if ! fc-list | grep -qi "$familia"; then
    tmp=$(mktemp -d)
    curl -fsSL -o "$tmp/$zip.zip" "https://github.com/ryanoasis/nerd-fonts/releases/latest/download/$zip.zip"
    unzip -oq "$tmp/$zip.zip" -d "$HOME/.local/share/fonts/$zip"
    rm -rf "$tmp"
  fi
done
fc-cache -f

echo "[5/5] Wallpapers..."
mkdir -p "$HOME/Pictures/wallpapers"
cp -n "$REPO"/wallpapers/* "$HOME/Pictures/wallpapers/" 2>/dev/null || true

echo "Listo. Cierra sesión y elige bspwm en la pantalla de login."
[[ -d "$BACKUP" ]] && echo "Tus configuraciones anteriores están en: $BACKUP"
