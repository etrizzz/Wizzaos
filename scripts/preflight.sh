#!/usr/bin/env bash
set -euo pipefail

# WizzaOS preflight gate
# Read-only checks: this script does not modify the machine.

PASS=0
WARN=0
FAIL=0

pass() { printf 'PASS  %s\n' "$*"; PASS=$((PASS + 1)); }
warn() { printf 'WARN  %s\n' "$*"; WARN=$((WARN + 1)); }
fail() { printf 'FAIL  %s\n' "$*"; FAIL=$((FAIL + 1)); }

printf '=== WizzaOS preflight ===\n'
printf 'Date: %s\n\n' "$(date --iso-8601=seconds 2>/dev/null || date)"

# Architecture
arch="$(uname -m)"
if [[ "$arch" == "x86_64" ]]; then
  pass "Architecture x86-64 détectée"
else
  fail "Architecture non supportée pour cette édition: $arch"
fi

# Memory. A PC sold as 6 GB generally exposes slightly less to Linux.
mem_kib="$(awk '/^MemTotal:/ {print $2}' /proc/meminfo)"
mem_mib=$((mem_kib / 1024))
if (( mem_mib >= 5200 )); then
  pass "Mémoire compatible avec le profil WizzaOS 6G: ${mem_mib} MiB utilisables"
elif (( mem_mib >= 3800 )); then
  warn "Seulement ${mem_mib} MiB utilisables: mode allégé recommandé"
else
  fail "Mémoire trop faible pour la cible actuelle: ${mem_mib} MiB"
fi

# CPU basic capability
cpu_model="$(lscpu 2>/dev/null | awk -F: '/Model name/ {sub(/^[[:space:]]+/, "", $2); print $2; exit}')"
[[ -n "$cpu_model" ]] && pass "CPU détecté: $cpu_model" || warn "Modèle CPU non déterminé"

if grep -qw lm /proc/cpuinfo; then
  pass "CPU capable d'exécuter un système 64 bits"
else
  fail "Drapeau CPU 64 bits (lm) absent"
fi

# Firmware boot mode
if [[ -d /sys/firmware/efi ]]; then
  pass "Démarrage UEFI détecté"
else
  warn "Démarrage Legacy/BIOS détecté; WizzaOS devra conserver la compatibilité BIOS"
fi

# Storage overview and SSD/HDD detection
if command -v lsblk >/dev/null 2>&1; then
  mapfile -t disks < <(lsblk -dn -o NAME,TYPE | awk '$2=="disk" {print $1}')
  if ((${#disks[@]} == 0)); then
    warn "Aucun disque physique détecté"
  else
    for disk in "${disks[@]}"; do
      rota="$(lsblk -dn -o ROTA "/dev/$disk" 2>/dev/null | tr -d ' ')"
      size="$(lsblk -dn -o SIZE "/dev/$disk" 2>/dev/null | xargs)"
      model="$(lsblk -dn -o MODEL "/dev/$disk" 2>/dev/null | xargs)"
      if [[ "$rota" == "0" ]]; then
        pass "Stockage /dev/$disk: SSD/non rotatif, ${size:-taille inconnue} ${model:-}"
      elif [[ "$rota" == "1" ]]; then
        warn "Stockage /dev/$disk: HDD mécanique, ${size:-taille inconnue} ${model:-} — un SSD apporterait le plus gros gain de réactivité"
      else
        warn "Type de stockage inconnu pour /dev/$disk"
      fi
    done
  fi
else
  warn "lsblk indisponible"
fi

# Root free space when running from an installed/live Linux environment.
if command -v df >/dev/null 2>&1; then
  free_kib="$(df -Pk / 2>/dev/null | awk 'NR==2 {print $4}')"
  if [[ "$free_kib" =~ ^[0-9]+$ ]]; then
    free_gib=$((free_kib / 1024 / 1024))
    if (( free_gib >= 30 )); then
      pass "Espace libre actuel: ~${free_gib} GiB"
    elif (( free_gib >= 15 )); then
      warn "Espace libre actuel limité: ~${free_gib} GiB"
    else
      warn "Moins de 15 GiB libres sur le système courant"
    fi
  fi
fi

# Graphics information. Vulkan is optional: old GPUs may still be useful for Prismatique/web.
if command -v lspci >/dev/null 2>&1; then
  gpu="$(lspci | grep -Ei 'VGA compatible controller|3D controller|Display controller' | head -n1 || true)"
  [[ -n "$gpu" ]] && pass "GPU détecté: $gpu" || warn "GPU non identifié"
else
  warn "lspci indisponible; GPU non vérifié"
fi

if command -v vulkaninfo >/dev/null 2>&1 && vulkaninfo --summary >/dev/null 2>&1; then
  pass "Vulkan fonctionnel: profil gaming avancé potentiellement disponible"
else
  warn "Vulkan non confirmé: ne bloque pas le profil Prismatique, mais peut limiter certains jeux Proton"
fi

# Network hardware check
if command -v lspci >/dev/null 2>&1 && lspci | grep -Eqi 'Network controller|Ethernet controller'; then
  pass "Contrôleur réseau détecté"
else
  warn "Contrôleur réseau PCI non confirmé"
fi

printf '\n=== Résumé ===\n'
printf 'PASS=%d WARN=%d FAIL=%d\n' "$PASS" "$WARN" "$FAIL"

if (( FAIL > 0 )); then
  printf 'Verdict: BLOQUÉ — corriger les échecs avant installation.\n'
  exit 2
fi

if (( WARN > 0 )); then
  printf 'Verdict: COMPATIBLE AVEC ADAPTATIONS — utiliser le profil conseillé par les avertissements.\n'
  exit 0
fi

printf 'Verdict: COMPATIBLE — profil WizzaOS 6G standard.\n'
