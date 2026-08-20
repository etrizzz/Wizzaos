#!/bin/sh
set -eu

export DEBIAN_FRONTEND=noninteractive

if [ "$(dpkg --print-architecture)" = "amd64" ]; then
    if ! dpkg --print-foreign-architectures | grep -qx i386; then
        dpkg --add-architecture i386
    fi
    apt-get update
    apt-get install -y --no-install-recommends wine32:i386 libwine:i386
fi

locale-gen fr_FR.UTF-8
update-locale LANG=fr_FR.UTF-8 LANGUAGE=fr_FR:fr

# Preserve the distribution-provided Calamares module defaults and override
# only the WizzaOS-owned profile. This keeps required common module configs
# such as mount/fstab/machineid/locale/umount available to the installer.
if [ -d /usr/share/wizzaos/calamares ]; then
    install -d /etc/calamares/modules /etc/calamares/branding/wizzaos
    cp /usr/share/wizzaos/calamares/settings.conf /etc/calamares/settings.conf
    cp /usr/share/wizzaos/calamares/modules/*.conf /etc/calamares/modules/
    cp -a /usr/share/wizzaos/calamares/branding/wizzaos/. /etc/calamares/branding/wizzaos/
fi
