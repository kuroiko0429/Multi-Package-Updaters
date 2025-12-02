# Multi-Package Updaters

A collection of shell scripts to streamline package management updates across different operating systems and package managers.

## Table of Contents
- [Multi-Package Updaters](#multi-package-updaters)
  - [Table of Contents](#table-of-contents)
  - [Scripts Overview](#scripts-overview)
  - [Installation](#installation)
  - [Usage](#usage)
    - [Arch Linux (pacman/yay) Update Script](#arch-linux-pacman-yay-update-script)
    - [Homebrew Update Script](#homebrew-update-script)
    - [Kali Linux / Debian (apt) Update Script](#kali-linux--debian-apt-update-script)
    - [Termux (pkg) Update Script](#termux-pkg-update-script)
  - [Contribution](#contribution)
  - [License](#license)

## Scripts Overview

This repository contains the following scripts:
- `archlinux_pacman_update_script.sh`: For Arch Linux systems, updates official packages via `pacman` and AUR packages via `yay`. (Primarily Japanese output)
- `homebrew_update_script.sh`: For macOS/Linux with Homebrew, updates Homebrew formulae and casks. (Primarily Japanese output)
- `kali_apt_update_script.sh`: For Debian-based systems, including Kali Linux, updates packages via `apt`. (Primarily English output)
- `termux_pkg_update_script.sh`: For Termux on Android, updates packages via `pkg`. (Primarily Japanese output)

## Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/YOUR_USERNAME/Multi-Package-Updaters.git
    cd Multi-Package-Updaters
    ```
    *Note: Replace `YOUR_USERNAME` with your actual GitHub username or the repository owner's username if forking.*

2.  **Make scripts executable:**
    ```bash
    chmod +x *.sh
    ```

## Usage

Each script is designed to be run on its respective system. It is highly recommended to review the script's content before execution.

### Arch Linux (pacman/yay) Update Script
**File:** `archlinux_pacman_update_script.sh`

This script automates the update process for Arch Linux, handling both official repositories (`pacman`) and the AUR (`yay`). It performs checks, displays system status, and offers options for updating.

**Prerequisites:**
- `pacman` (standard on Arch Linux)
- `yay` (optional, for AUR updates; if not found, AUR updates are skipped)

**Usage:**
```bash
./archlinux_pacman_update_script.sh [options]
```

**Options:**
- `-h`, `--help`: Show help message.
- `-f`, `--force`: Execute updates without confirmation.
- `-c`, `--check`: Only check for updates (do not update).
- `-p`, `--pacman-only`: Only update pacman packages (skip AUR).
- `-a`, `--aur-only`: Only update AUR packages.
- `-n`, `--no-sudo`: Do not use `sudo` (assumes script is run as root).
- `-q`, `--quiet`: Suppress detailed output.

### Homebrew Update Script
**File:** `homebrew_update_script.sh`

This script simplifies updating Homebrew packages (formulae) and Casks (applications) on macOS and Linux systems where Homebrew is installed.

**Prerequisites:**
- Homebrew (installed and configured)

**Usage:**
```bash
./homebrew_update_script.sh
```

The script will check for outdated packages and prompt you before performing `brew update` and `brew upgrade`.

### Kali Linux / Debian (apt) Update Script
**File:** `kali_apt_update_script.sh`

This script provides a comprehensive update solution for Debian-based distributions, including Kali Linux. It supports standard upgrades and distribution upgrades, with options for cleanup.

**Prerequisites:**
- `apt` (standard on Debian-based systems)

**Usage:**
```bash
./kali_apt_update_script.sh [options]
```

**Options:**
- `-h`, `--help`: Show help message.
- `-f`, `--force`: Execute updates without confirmation.
- `-c`, `--check`: Check only (do not update).
- `-d`, `--dist-upgrade`: Use `dist-upgrade` instead of `upgrade`.
- `-F`, `--full-upgrade`: Use `full-upgrade` (same as `dist-upgrade`).
- `-n`, `--no-sudo`: Do not use `sudo` (assumes script is run as root).
- `-q`, `--quiet`: Suppress detailed output.
- `--auto-cleanup`: Automatically run `apt autoremove` and `apt clean` after update.

### Termux (pkg) Update Script
**File:** `termux_pkg_update_script.sh`

Designed specifically for Termux on Android, this script manages package updates using the `pkg` package manager.

**Prerequisites:**
- Termux environment

**Usage:**
```bash
./termux_pkg_update_script.sh [options]
```

**Options:**
- `-h`, `--help`: Show help message.
- `-f`, `--force`: Execute updates without confirmation.
- `-c`, `--check`: Only check for updates (do not update).
- `-q`, `--quiet`: Suppress detailed output.

## Contribution

If you have suggestions for improvements or new scripts, feel free to open an issue or submit a pull request.

## License

This project is licensed under the [MIT License](LICENSE).
