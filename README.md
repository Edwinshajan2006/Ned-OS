# NED-OS

<div align="center">
  <img src="./profile-banner.svg" width="100%" alt="NED-OS project banner" />
</div>

NED-OS is a personal Linux customization and productivity project. It began on Linux Mint and is now developed primarily on Fedora Workstation with GNOME, Wayland and Fish.

## Repository layout

- `Fedora/` - current Fedora workstation configuration.
- `Linux-Mint/` - legacy Debian/Ubuntu and XFCE components.
- `Shared/` - cross-platform assets and browser tools.
- `assets/` - project branding and wallpapers.
- `terminal-v2/` - terminal and shell configuration under review.

## Fedora

The Fedora folder currently includes the NED-OS Fastfetch configuration and logo.

Install the Fastfetch configuration for your user:

```bash
mkdir -p ~/.config/fastfetch
cp Fedora/fastfetch/config.jsonc Fedora/fastfetch/ned-logo.txt ~/.config/fastfetch/
fastfetch
```

This copies configuration only. It does not install packages or change system settings.

## Linux Mint

The `Linux-Mint/` directory contains the legacy APT-based installer and Linux Mint/XFCE utilities. Do not run its installer on Fedora.

## Shared browser tools

The NED Focus Guard browser extension is stored under `Shared/Browser/Focus-Guard/`. It is a Chromium Manifest V3 extension and must be loaded manually through the browser's extension developer mode.

## Development approach

The repository is being reorganized in small daily batches of no more than 20 changed files. Platform-specific scripts should stay in their platform folder; shared assets should remain independent of desktop environment.

Review scripts before running them. Machine-specific configuration, secrets and Fish universal-variable dumps must not be committed.
