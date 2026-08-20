#!/bin/sh
set -eu

export DEBIAN_FRONTEND=noninteractive

# Old Windows software is very often 32-bit. Ubuntu's Wine packages still
# provide the classic i386 loader, so WizzaOS enables multiarch in the image.
if [ "$(dpkg --print-architecture)" = "amd64" ]; then
    if ! dpkg --print-foreign-architectures | grep -qx i386; then
        dpkg --add-architecture i386
    fi
    apt-get update
    apt-get install -y --no-install-recommends wine32:i386 libwine:i386
fi

# The live session and the installed system must be usable in French without
# requiring a first-login language download.
locale-gen fr_FR.UTF-8
update-locale LANG=fr_FR.UTF-8 LANGUAGE=fr_FR:fr
