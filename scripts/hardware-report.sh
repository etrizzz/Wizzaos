#!/usr/bin/env bash
set -euo pipefail

printf '=== WizzaOS Hardware Report ===\n'
printf 'Date: '; date --iso-8601=seconds
printf '\n-- CPU --\n'
lscpu | grep -E 'Model name|Architecture|CPU\(s\)|Thread|Core|MHz' || true
printf '\n-- Memory --\n'
free -h
printf '\n-- GPU / display --\n'
lspci -nnk | grep -EA3 'VGA|3D|Display' || true
printf '\n-- Storage --\n'
lsblk -o NAME,MODEL,SIZE,ROTA,TYPE,FSTYPE,MOUNTPOINTS
printf '\n-- Network --\n'
lspci -nnk | grep -EA3 'Network|Ethernet' || true
printf '\n-- Kernel --\n'
uname -a
printf '\n-- OpenGL --\n'
command -v glxinfo >/dev/null && glxinfo -B || echo 'glxinfo not installed'
printf '\n-- Vulkan --\n'
command -v vulkaninfo >/dev/null && vulkaninfo --summary || echo 'vulkaninfo not installed'
printf '\n-- SMART status --\n'
if command -v smartctl >/dev/null; then
  while read -r disk; do
    echo "### $disk"
    sudo smartctl -H "$disk" 2>/dev/null || true
  done < <(lsblk -dpno NAME,TYPE | awk '$2=="disk" {print $1}')
else
  echo 'smartmontools not installed'
fi
