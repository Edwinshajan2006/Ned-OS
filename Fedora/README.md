# NED-OS for Fedora

Current Fedora workstation configuration.

## Fastfetch

This folder contains the NED-OS Fastfetch configuration and ASCII logo.

Install them for the current user:

```bash
mkdir -p ~/.config/fastfetch
cp Fedora/fastfetch/config.jsonc Fedora/fastfetch/ned-logo.txt ~/.config/fastfetch/
fastfetch
```

The configuration uses the custom NED-OS logo and displays OS, hardware, shell, desktop, network, battery, memory and storage information.

This is a configuration copy, not a system installer. It does not install packages or modify system settings.
