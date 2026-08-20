#!/usr/bin/env bash
set -euo pipefail

if ! command -v zenity >/dev/null 2>&1; then
  echo "Wizza Center nécessite zenity." >&2
  exit 1
fi

while true; do
  choice="$(zenity --list \
    --title="Wizza Center" \
    --text="Centre de contrôle WizzaOS" \
    --width=660 --height=470 \
    --column="Section" --column="Action" \
    "Prismatique" "Ouvrir l'espace de travail" \
    "IA" "Ouvrir ChatGPT / Gemini / Claude" \
    "Windows" "Vérifier la compatibilité .exe / .msi" \
    "Rétro" "Ouvrir DOSBox-X / ScummVM / RetroArch" \
    "Système" "Voir le diagnostic matériel" \
    "Performance" "Voir mémoire et charge" \
    "Gaming" "Ouvrir Steam s'il est installé" \
    "Mises à jour" "Ouvrir le gestionnaire de mises à jour" \
    "Quitter" "Fermer Wizza Center" 2>/dev/null || true)"

  case "$choice" in
    Prismatique)
      xdg-open "https://www.canva.com" >/dev/null 2>&1 &
      ;;
    IA)
      xdg-open "https://chatgpt.com" >/dev/null 2>&1 &
      xdg-open "https://gemini.google.com" >/dev/null 2>&1 &
      xdg-open "https://claude.ai" >/dev/null 2>&1 &
      ;;
    Windows)
      if command -v wine >/dev/null 2>&1; then
        wine_version="$(wine --version 2>/dev/null || true)"
        wine32_state="non confirmé"
        if dpkg -s wine32:i386 >/dev/null 2>&1; then
          wine32_state="installé"
        fi
        zenity --info --title="Compatibilité Windows" --width=560 \
          --text="Couche Windows disponible.\n\nWine : ${wine_version:-détecté}\nSupport 32 bits : $wine32_state\n\nDouble-clique sur un fichier .exe ou .msi pour le lancer avec WizzaOS."
      else
        zenity --error --title="Compatibilité Windows" --text="Wine n'est pas installé dans cette image WizzaOS."
      fi
      ;;
    Rétro)
      retro="$(zenity --list \
        --title="Wizza Rétro" \
        --text="Choisis le moteur à lancer" \
        --width=560 --height=330 \
        --column="Moteur" --column="Usage" \
        "DOSBox-X" "Jeux DOS / vieux jeux PC" \
        "ScummVM" "Jeux d'aventure compatibles" \
        "RetroArch" "Consoles rétro, dont PlayStation" 2>/dev/null || true)"
      case "$retro" in
        DOSBox-X) command -v dosbox-x >/dev/null 2>&1 && dosbox-x >/dev/null 2>&1 & ;;
        ScummVM) command -v scummvm >/dev/null 2>&1 && scummvm >/dev/null 2>&1 & ;;
        RetroArch) command -v retroarch >/dev/null 2>&1 && retroarch >/dev/null 2>&1 & ;;
      esac
      ;;
    Système)
      report="$(mktemp)"
      wizza-hardware-report >"$report" 2>&1 || true
      zenity --text-info --title="Diagnostic WizzaOS" --filename="$report" --width=800 --height=600
      rm -f "$report"
      ;;
    Performance)
      info="$(printf 'Mémoire\n%s\n\nCharge\n%s\n' "$(free -h)" "$(uptime)")"
      zenity --info --title="Performance WizzaOS" --width=640 --text="$info"
      ;;
    Gaming)
      if command -v steam >/dev/null 2>&1; then
        steam >/dev/null 2>&1 &
      else
        zenity --info --title="Gaming WizzaOS" --text="Steam n'est pas installé dans le socle léger. Il restera installable à la demande."
      fi
      ;;
    "Mises à jour")
      if command -v update-manager >/dev/null 2>&1; then
        update-manager >/dev/null 2>&1 &
      else
        zenity --info --title="Mises à jour WizzaOS" --text="Le gestionnaire graphique de mises à jour n'est pas disponible."
      fi
      ;;
    Quitter|"")
      break
      ;;
  esac
done
