#!/usr/bin/env bash
set -euo pipefail

NED_DIR="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")" && pwd)"
NED_BIN="$HOME/.local/bin"

echo "================================"
echo "        NED-OS INSTALLER"
echo "================================"
echo

if ! command -v apt >/dev/null 2>&1; then
    echo "ERROR: This installer supports Debian/Ubuntu-based systems only."
    exit 1
fi

PACKAGES=(fastfetch xdotool network-manager bluez)
MISSING=()
for package in "${PACKAGES[@]}"; do
    if dpkg -s "$package" >/dev/null 2>&1; then
        printf '✓ %s\n' "$package"
    else
        printf '✗ %s\n' "$package"
        MISSING+=("$package")
    fi
done

if (("${#MISSING[@]}" > 0)); then
    sudo apt update
    sudo apt install -y "${MISSING[@]}"
fi

mkdir -p "$NED_BIN"
cat > "$NED_BIN/ned" <<EOF
#!/usr/bin/env bash
NED_OS_DIR="$NED_DIR" exec "$NED_DIR/scripts/ned-command-center.sh" "\$@"
EOF
chmod +x "$NED_BIN/ned"

if [[ ":$PATH:" != *":$NED_BIN:"* ]]; then
    printf '\nexport PATH="$HOME/.local/bin:$PATH"\n' >> "$HOME/.bashrc"
    export PATH="$NED_BIN:$PATH"
fi

echo
echo "NED-OS command installed."
echo "Run: ned help"
echo "Restart your terminal if ~/.local/bin is not already in PATH."
