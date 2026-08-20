#!/usr/bin/env bash
set -euo pipefail

if [[ ! -e /run/live/medium/live/filesystem.squashfs ]]; then
  if command -v zenity >/dev/null 2>&1; then
    zenity --error --title="Installer WizzaOS" --text="L'installateur doit être lancé depuis la session Live WizzaOS."
  fi
  exit 1
fi

if ! command -v calamares >/dev/null 2>&1; then
  if command -v zenity >/dev/null 2>&1; then
    zenity --error --title="Installer WizzaOS" --text="Calamares n'est pas disponible dans cette image."
  fi
  exit 1
fi

exec pkexec env DISPLAY="${DISPLAY:-:0}" XAUTHORITY="${XAUTHORITY:-$HOME/.Xauthority}" LANG=fr_FR.UTF-8 calamares -c /etc/calamares/settings.conf
