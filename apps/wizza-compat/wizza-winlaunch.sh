#!/usr/bin/env bash
set -euo pipefail

show_error() {
  local message="$1"
  if command -v zenity >/dev/null 2>&1; then
    zenity --error --title="WizzaOS — Application Windows" --text="$message" --width=520
  else
    printf 'WizzaOS: %s\n' "$message" >&2
  fi
}

if (($# < 1)); then
  show_error "Aucun fichier Windows n'a été fourni."
  exit 64
fi

target="$1"
if [[ ! -f "$target" ]]; then
  show_error "Le fichier n'existe pas :\n$target"
  exit 66
fi

if ! command -v wine >/dev/null 2>&1; then
  show_error "La couche de compatibilité Windows (Wine) n'est pas disponible."
  exit 69
fi

prefix="${WIZZA_WINEPREFIX:-$HOME/.local/share/wizzaos/wine/default}"
mkdir -p "$prefix"
export WINEPREFIX="$prefix"
export WINEDEBUG="${WINEDEBUG:--all}"

# WizzaOS keeps one shared 64-bit prefix. With wine32 installed through the
# image build, this also handles the large majority of older 32-bit programs.
if [[ ! -f "$prefix/system.reg" ]]; then
  if ! wineboot --init >/dev/null 2>&1; then
    show_error "WizzaOS n'a pas réussi à initialiser l'environnement Windows."
    exit 70
  fi
fi

lower="${target,,}"
case "$lower" in
  *.exe)
    exec wine start /unix "$target"
    ;;
  *.msi)
    windows_path="$(winepath -w "$target")"
    exec wine msiexec /i "$windows_path"
    ;;
  *.bat|*.cmd)
    windows_path="$(winepath -w "$target")"
    exec wine cmd /c "$windows_path"
    ;;
  *)
    show_error "Ce type de fichier Windows n'est pas encore pris en charge automatiquement."
    exit 65
    ;;
esac
