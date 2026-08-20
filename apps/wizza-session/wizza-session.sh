#!/usr/bin/env bash
set -euo pipefail

# WizzaOS desktop session entry point.
# XFCE remains the lightweight compositor/window-manager layer, while the
# visible session is identified as WizzaOS.
export XDG_CURRENT_DESKTOP="WizzaOS:XFCE"
export XDG_SESSION_DESKTOP="wizzaos"
export DESKTOP_SESSION="wizzaos"
export WIZZAOS_SESSION=1

exec startxfce4
