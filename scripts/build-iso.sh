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
  exit 1
fi

[[ "$(uname -m)" == "x86_64" ]] || { echo "ERROR: build amd64 requis." >&2; exit 1; }

for path in \
  "$REPO_ROOT/packages/base.txt" \
  "$REPO_ROOT/packages/desktop.txt" \
  "$REPO_ROOT/packages/compatibility.txt" \
  "$REPO_ROOT/packages/french.txt" \
  "$REPO_ROOT/packages/installer.txt" \
  "$REPO_ROOT/installer/calamares/settings.conf" \
  "$REPO_ROOT/scripts/chroot-finalize.sh" \
  "$REPO_ROOT/apps/wizza-center/wizza-center.sh" \
  "$REPO_ROOT/apps/wizza-session/wizza-session.sh" \
  "$REPO_ROOT/apps/wizza-compat/wizza-winlaunch.sh" \
  "$REPO_ROOT/apps/wizza-installer/wizza-installer.sh"; do
  [[ -f "$path" ]] || { echo "ERROR: fichier requis absent: $path" >&2; exit 1; }
done

rm -rf -- "$WORK_DIR"
mkdir -p "$WORK_DIR" "$DIST_DIR"
cd "$WORK_DIR"

lb_help="$(lb config --help 2>&1 || true)"
if grep -q -- '--architecture ' <<<"$lb_help"; then arch_opt=(--architecture amd64); else arch_opt=(--architectures amd64); fi
if grep -q -- '--binary-image ' <<<"$lb_help"; then binary_opt=(--binary-image iso-hybrid); else binary_opt=(--binary-images iso-hybrid); fi

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
  --bootappend-live "boot=live components quiet splash hostname=wizzaos locales=fr_FR.UTF-8 keyboard-layouts=fr"

mkdir -p config/package-lists
cp "$REPO_ROOT/packages/base.txt" config/package-lists/wizza-base.list.chroot
cp "$REPO_ROOT/packages/desktop.txt" config/package-lists/wizza-desktop.list.chroot
cp "$REPO_ROOT/packages/compatibility.txt" config/package-lists/wizza-compatibility.list.chroot
cp "$REPO_ROOT/packages/french.txt" config/package-lists/wizza-french.list.chroot
cp "$REPO_ROOT/packages/installer.txt" config/package-lists/wizza-installer.list.chroot

mkdir -p config/includes.chroot
[[ -d "$REPO_ROOT/overlay" ]] && rsync -a "$REPO_ROOT/overlay/" config/includes.chroot/
mkdir -p config/includes.chroot/usr/share/wizzaos/calamares
rsync -a "$REPO_ROOT/installer/calamares/" config/includes.chroot/usr/share/wizzaos/calamares/

mkdir -p config/includes.chroot/etc/systemd config/includes.chroot/etc/sysctl.d config/includes.chroot/usr/local/sbin config/includes.chroot/usr/local/bin config/hooks/live
cp "$REPO_ROOT/config/systemd/zram-generator.conf" config/includes.chroot/etc/systemd/zram-generator.conf
cp "$REPO_ROOT/config/sysctl.d/90-wizza-6g.conf" config/includes.chroot/etc/sysctl.d/90-wizza-6g.conf
install -m 0755 "$REPO_ROOT/scripts/hardware-report.sh" config/includes.chroot/usr/local/sbin/wizza-hardware-report
install -m 0755 "$REPO_ROOT/scripts/preflight.sh" config/includes.chroot/usr/local/sbin/wizza-preflight
install -m 0755 "$REPO_ROOT/apps/wizza-center/wizza-center.sh" config/includes.chroot/usr/local/bin/wizza-center
install -m 0755 "$REPO_ROOT/apps/wizza-session/wizza-session.sh" config/includes.chroot/usr/local/bin/wizza-session
install -m 0755 "$REPO_ROOT/apps/wizza-compat/wizza-winlaunch.sh" config/includes.chroot/usr/local/bin/wizza-winlaunch
install -m 0755 "$REPO_ROOT/apps/wizza-installer/wizza-installer.sh" config/includes.chroot/usr/local/bin/wizza-installer
install -m 0755 "$REPO_ROOT/scripts/chroot-finalize.sh" config/hooks/live/0100-wizza-finalize.hook.chroot

echo "Construction de l'image WizzaOS…"
lb build

iso="$(find "$WORK_DIR" -maxdepth 1 -type f -name '*.iso' -print -quit)"
[[ -n "$iso" ]] || { echo "ERROR: aucune ISO produite." >&2; exit 1; }
output="$DIST_DIR/WizzaOS-${CODENAME}-amd64-live.iso"
cp -- "$iso" "$output"
sha256sum "$output" > "$output.sha256"
printf 'OK: %s\n' "$output"
