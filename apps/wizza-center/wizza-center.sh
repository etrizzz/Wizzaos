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
    --width=620 --height=420 \
    --column="Section" --column="Action" \
    "Prismatique" "Ouvrir l'espace de travail" \
    "IA" "Ouvrir ChatGPT / Gemini / Claude" \
    "Système" "Voir le diagnostic matériel" \
    "Performance" "Voir mémoire et charge" \
    "Gaming" "Préparer Steam / Proton" \
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
        zenity --info --title="Gaming WizzaOS" --text="Steam n'est pas encore installé. Cette fonction sera intégrée au profil Gaming."
      fi
      ;;
    "Mises à jour")
      if command -v update-manager >/dev/null 2>&1; then
        update-manager >/dev/null 2>&1 &
      else
        zenity --info --title="Mises à jour WizzaOS" --text="Le gestionnaire graphique de mises à jour n'est pas encore installé."
      fi
      ;;
    Quitter|"")
      break
      ;;
  esac
done
