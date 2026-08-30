#!/usr/bin/env bash
set -e

NED_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
NED_BIN="$HOME/.local/bin"

echo "================================"
echo "        NED-OS INSTALLER"
echo "================================"
echo

echo "[1/5] Checking system..."

if ! command -v apt >/dev/null 2>&1; then
    echo "ERROR: This installer currently supports Debian/Ubuntu-based systems."
    exit 1
fi

echo "✓ Debian/Ubuntu-based system detected"

echo
echo "[2/5] Checking dependencies..."

PACKAGES=(
    fastfetch
    xdotool
    network-manager
    bluez
)

MISSING=()

for package in "${PACKAGES[@]}"; do
    if dpkg -s "$package" >/dev/null 2>&1; then
        echo "✓ $package"
    else
        echo "✗ $package"
        MISSING+=("$package")
    fi
done

if [ "${#MISSING[@]}" -gt 0 ]; then
    echo
    echo "Installing missing packages..."

    sudo apt update
    sudo apt install -y "${MISSING[@]}"
fi

echo
echo "[3/5] Installing NED command..."

mkdir -p "$NED_BIN"

cp "$NED_DIR/scripts/ned" "$NED_BIN/ned"
chmod +x "$NED_BIN/ned"

echo "✓ NED command installed"

echo
echo "[4/5] Checking PATH..."

if [[ ":$PATH:" != *":$NED_BIN:"* ]]; then
    echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$HOME/.bashrc"
    export PATH="$NED_BIN:$PATH"
    echo "✓ Added ~/.local/bin to PATH"
else
    echo "✓ ~/.local/bin already in PATH"
fi

echo
echo "[5/5] Verifying NED-OS..."

if command -v ned >/dev/null 2>&1; then
    echo "✓ NED command available"
else
    echo "ERROR: NED command could not be installed."
    exit 1
fi

echo
echo "================================"
echo "       NED-OS INSTALLED"
echo "================================"
echo
echo "Try:"
echo
echo "  ned help"
echo "  ned info"
echo "  ned status"
echo
echo "Restart your terminal if needed."
echo

