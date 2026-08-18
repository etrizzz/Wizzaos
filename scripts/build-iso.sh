#!/usr/bin/env bash
set -euo pipefail
REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
WORK_DIR="${WIZZA_BUILD_DIR:-$REPO_ROOT/.build/live}"
DIST_DIR="${WIZZA_DIST_DIR:-$REPO_ROOT/dist}"
CODENAME="${WIZZA_CODENAME:-resolute}"
IMAGE_NAME="${WIZZA_IMAGE_NAME:-wizzaos}"

if [[ "${EUID}" -ne 0 ]]; then
  if command -v sudo >/dev/null 2>&1; then
    exec sudo --preserve-env=WIZZA_BUILD_DIR,WIZZA_DIST_DIR,WIZZA_CODENAME,WIZZA_IMAGE_NAME "$0" "$@"
  fi
  echo "ERROR: ce build nécessite les privilèges root (live-build/chroot)." >&2
  exit 1
fi

required=(lb debootstrap xorriso mksquashfs rsync sha256sum)
missing=()
for cmd in "${required[@]}"; do
  command -v "$cmd" >/dev/null 2>&1 || missing+=("$cmd")
done
if ((${#missing[@]})); then
  printf 'ERROR: outils manquants: %s\n' "${missing[*]}" >&2
  echo "Sur Ubuntu 26.04: apt install live-build debootstrap xorriso squashfs-tools rsync" >&2
  exit 1
fi

[[ "$(uname -m)" == "x86_64" ]] || {
  echo "ERROR: le builder WizzaOS amd64 doit tourner sur un hôte x86-64." >&2
  exit 1
}

for path in \
  "$REPO_ROOT/packages/base.txt" \
  "$REPO_ROOT/config/systemd/zram-generator.conf" \
  "$REPO_ROOT/config/sysctl.d/90-wizza-6g.conf" \
  "$REPO_ROOT/scripts/hardware-report.sh" \
  "$REPO_ROOT/scripts/preflight.sh"; do
  [[ -f "$path" ]] || { echo "ERROR: fichier requis absent: $path" >&2; exit 1; }
done

echo "=== WizzaOS ISO Builder ==="
echo "Base: Ubuntu $CODENAME / amd64"
echo "Work: $WORK_DIR"

if [[ -z "${WIZZA_BUILD_DIR:-}" && "$WORK_DIR" != "$REPO_ROOT/.build/live" ]]; then
  echo "ERROR: garde-fou de chemin de build déclenché." >&2
  exit 1
fi
rm -rf -- "$WORK_DIR"
mkdir -p "$WORK_DIR" "$DIST_DIR"
cd "$WORK_DIR"

lb_help="$(lb config --help 2>&1 || true)"
if grep -q -- '--architecture ' <<<"$lb_help"; then
  arch_opt=(--architecture amd64)
else
  arch_opt=(--architectures amd64)
fi
if grep -q -- '--binary-image ' <<<"$lb_help"; then
  binary_opt=(--binary-image iso-hybrid)
else
  binary_opt=(--binary-images iso-hybrid)
fi

lb config \
  --mode ubuntu \
  --distribution "$CODENAME" \
  "${arch_opt[@]}" \
  "${binary_opt[@]}" \
  --archive-areas "main restricted universe multiverse" \
  --apt-recommends false \
  --apt-source-archives false \
  --security true \
  --updates true \
  --image-name "$IMAGE_NAME" \
  --iso-application "WizzaOS Live" \
  --iso-publisher "WizzaOS Project" \
  --iso-volume "WIZZAOS" \
  --bootappend-live "boot=live components quiet splash hostname=wizzaos"

mkdir -p config/package-lists
cp "$REPO_ROOT/packages/base.txt" config/package-lists/wizza.list.chroot

mkdir -p config/includes.chroot/etc/systemd config/includes.chroot/etc/sysctl.d config/includes.chroot/usr/local/sbin
cp "$REPO_ROOT/config/systemd/zram-generator.conf" config/includes.chroot/etc/systemd/zram-generator.conf
cp "$REPO_ROOT/config/sysctl.d/90-wizza-6g.conf" config/includes.chroot/etc/sysctl.d/90-wizza-6g.conf
install -m 0755 "$REPO_ROOT/scripts/hardware-report.sh" config/includes.chroot/usr/local/sbin/wizza-hardware-report
install -m 0755 "$REPO_ROOT/scripts/preflight.sh" config/includes.chroot/usr/local/sbin/wizza-preflight

echo "Construction de l'image live…"
lb build

iso="$(find "$WORK_DIR" -maxdepth 1 -type f -name '*.iso' -print -quit)"
[[ -n "$iso" ]] || {
  echo "ERROR: live-build s'est terminé sans produire d'ISO." >&2
  exit 1
}

output="$DIST_DIR/WizzaOS-${CODENAME}-amd64-live.iso"
cp -- "$iso" "$output"
sha256sum "$output" > "$output.sha256"

echo
echo "OK: $output"
echo "SHA256: $output.sha256"
echo "Cette image est destinée au test live. Ne pas l'utiliser comme installateur final."
