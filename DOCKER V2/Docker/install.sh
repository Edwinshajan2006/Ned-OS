#!/usr/bin/env bash
set -e
UUID="radial-dock@ned"
DEST="$HOME/.local/share/gnome-shell/extensions/$UUID"
mkdir -p "$DEST"
cp -r "$(dirname "$0")/"{extension.js,metadata.json,schemas} "$DEST/"
glib-compile-schemas "$DEST/schemas"
echo "Installed to $DEST"
echo "Log out and back in (Wayland needs this), then run:"
echo "  gnome-extensions enable $UUID"
echo "Press Super+D to open the dock."
