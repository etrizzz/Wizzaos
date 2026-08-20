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

# Install the WizzaOS-owned Calamares profile after package installation, so
# distribution package defaults cannot overwrite our installer configuration.
if [ -d /usr/share/wizzaos/calamares ]; then
    rm -rf /etc/calamares
    mkdir -p /etc/calamares
    cp -a /usr/share/wizzaos/calamares/. /etc/calamares/
fi
