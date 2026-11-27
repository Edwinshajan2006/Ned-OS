# NED-OS

A personal Linux customization and productivity project, developed on Linux Mint and later migrated to Fedora.

## Daily restructure

This repository is being reorganized in small, reviewable batches of no more than 20 changed files per day.

## Planned layout

- `Linux-Mint/` - legacy Debian/Ubuntu and XFCE setup.
- `Fedora/` - current Fedora workstation configuration and GNOME components.
- `Shared/` - branding, wallpapers and browser tools.
- `docs/` - project history and documentation.

The current batch moves the core Linux Mint installer and command utilities. Remaining files will be moved in later batches.

## Platform notes

The Linux Mint installer uses APT and is not a Fedora installer. Several legacy desktop scripts target XFCE/X11. Fedora GNOME and Fish components will be handled separately.

Review scripts before running them. Machine-specific configuration, secrets and Fish universal-variable dumps must not be committed.
