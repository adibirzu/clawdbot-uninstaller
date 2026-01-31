# Clawdbot, Molbot, and OpenClaw Uninstaller

A comprehensive uninstall script for safely removing [Clawdbot](https://github.com/clawdbot/clawdbot), [Molbot](https://github.com/molbot/molbot), and [OpenClaw](https://openclaw.ai/) from macOS and Linux systems.

## Overview

This script provides a complete uninstallation solution that:

- **Uses standard product uninstall capabilities** where available through package managers (Homebrew, APT, DNF, Pacman, Snap, Flatpak, npm, pip)
- **Performs comprehensive cleanup** to detect and remove orphaned files, missing packages, and leftover configurations
- **Creates automatic backups** of all configuration files, credentials, and custom skills before removal
- **Supports multiple platforms** (macOS and Linux) with platform-specific service management

## Features

### ✅ Comprehensive Removal

- Terminates all running processes (including browser instances)
- Removes data directories (`~/.clawdbot`, `~/.molbot`, `~/.openclaw`)
- Cleans up service files:
  - **macOS**: LaunchAgents and LaunchDaemons
  - **Linux**: systemd user and system services
- Removes executables from common locations
- Uninstalls packages from all supported package managers
- Detects and prompts for removal of orphaned files

### 🔍 Missing Package Detection

The script actively searches for:
- Orphaned files in common application directories
- Leftover browser data and cache files
- Abandoned configuration files
- Shell configuration references
- Python packages (pip/pip3)
- Node.js packages (npm)
- System-wide and user-local installations

### 💾 Automatic Backup

Before removal, the script creates a timestamped backup containing:
- Settings and configuration files
- Credentials and identity files
- Custom skills and agents
- All `.json`, `.yaml`, `.yml`, `.conf`, and `.toml` files
- A README with restoration instructions

**Backup Location:**
- **macOS**: `~/Desktop/clawdbot-molbot-openclaw-backup-YYYYMMDD-HHMMSS/`
- **Linux**: `~/clawdbot-molbot-openclaw-backup-YYYYMMDD-HHMMSS/`

## Supported Platforms

### macOS
- macOS 10.15 (Catalina) and later
- Both Intel and Apple Silicon

### Linux
- Ubuntu / Debian (APT)
- Fedora / RHEL / CentOS (DNF/YUM)
- Arch Linux (Pacman)
- Any systemd-based distribution
- Snap and Flatpak support

## Package Managers Supported

- **macOS**: Homebrew, npm, pip
- **Linux**: APT, DNF, YUM, Pacman, Snap, Flatpak, npm, pip

## Installation

### Quick Install (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/adibirzu/clawdbot-uninstaller/main/uninstall.sh -o uninstall.sh
chmod +x uninstall.sh
```

### Manual Install

1. Download the script:
   ```bash
   git clone https://github.com/adibirzu/clawdbot-uninstaller.git
   cd clawdbot-uninstaller
   ```

2. Make it executable:
   ```bash
   chmod +x uninstall.sh
   ```

## Usage

Run the script:

```bash
./uninstall.sh
```

The script will:
1. Detect your operating system (macOS or Linux)
2. Display what will be removed
3. Ask for confirmation before proceeding
4. Create a backup of all configurations
5. Remove all installed components
6. Check for and optionally remove orphaned files

### Interactive Prompts

The script will prompt you for:
- **Initial confirmation** before starting the uninstall process
- **Individual file removal** when orphaned files are detected

### Non-Interactive Mode

For automated deployments, you can pipe 'yes' to the script:

```bash
yes | ./uninstall.sh
```

**⚠️ Warning**: This will automatically remove all orphaned files without prompting.

## What Gets Removed

### Data Directories
- `~/.clawdbot/`
- `~/.molbot/`
- `~/.openclaw/`

### Service Files
**macOS:**
- `~/Library/LaunchAgents/*clawdbot*`
- `~/Library/LaunchAgents/*molbot*`
- `~/Library/LaunchAgents/*openclaw*`
- `/Library/LaunchAgents/*` (system-wide, requires sudo)
- `/Library/LaunchDaemons/*` (system-wide, requires sudo)

**Linux:**
- `~/.config/systemd/user/*clawdbot*`
- `~/.config/systemd/user/*molbot*`
- `~/.config/systemd/user/*openclaw*`
- `/etc/systemd/system/*` (system-wide, requires sudo)

### Executables
- `/usr/local/bin/{clawdbot,molbot,openclaw,clawd,moltbot-gateway}`
- `~/.local/bin/{clawdbot,molbot,openclaw,clawd,moltbot-gateway}`
- `/opt/homebrew/bin/` (macOS only)

### Package Installations
- npm global packages
- pip/pip3 packages
- Homebrew formulae (macOS)
- APT packages (Debian/Ubuntu)
- DNF/YUM packages (Fedora/RHEL)
- Pacman packages (Arch)
- Snap packages
- Flatpak packages

### Orphaned Files
The script searches and optionally removes files from:
- `/Applications/` (macOS)
- `~/Library/Application Support/` (macOS)
- `~/Library/Caches/` (macOS)
- `/usr/local/share/`
- `/usr/share/` (Linux)
- `~/.config/` (Linux)
- `~/.cache/` (Linux)
- `~/.local/share/` (Linux)

## What Gets Backed Up

All configuration files and skills are backed up before removal:

```
backup-YYYYMMDD-HHMMSS/
├── README.txt
├── clawdbot/
│   ├── settings/
│   ├── credentials/
│   ├── identity/
│   ├── agents/
│   ├── skills/
│   └── exec-approvals.json
├── molbot/
│   ├── settings/
│   ├── credentials/
│   └── config/
└── openclaw/
    ├── settings/
    ├── credentials/
    └── config/
```

## Restoring from Backup

To restore your configuration:

1. Locate your backup directory
2. Copy files back to their original locations:
   ```bash
   cp -R ~/Desktop/clawdbot-molbot-openclaw-backup-*/clawdbot/* ~/.clawdbot/
   cp -R ~/Desktop/clawdbot-molbot-openclaw-backup-*/molbot/* ~/.molbot/
   cp -R ~/Desktop/clawdbot-molbot-openclaw-backup-*/openclaw/* ~/.openclaw/
   ```

## Requirements

- Bash 4.0 or later
- `find`, `grep`, `sed`, `awk` (standard on all Unix-like systems)
- `sudo` access (only if system-wide installations are detected)

### Optional
- Package managers (Homebrew, APT, DNF, etc.) - only used if installed
- `npm` - for Node.js package removal
- `pip` or `pip3` - for Python package removal

## Safety Features

- **No root requirement**: Script runs as regular user and requests sudo only when needed
- **Automatic backups**: All configurations backed up before any removal
- **Interactive prompts**: Confirms before removing orphaned files
- **Dry-run friendly**: Review what will be removed before confirming
- **Non-destructive**: Only removes files explicitly related to these applications

## Troubleshooting

### Permission Denied Errors

If you encounter permission errors:

```bash
# Make the script executable
chmod +x uninstall.sh

# Run with your user account (not root)
./uninstall.sh
```

### Script Won't Run

Ensure you have Bash installed:

```bash
bash --version
```

If Bash is not available, install it through your package manager.

### Orphaned Files Remain

After running the script, manually check:

**macOS:**
- `~/Library/Application Support/`
- `~/Library/Preferences/`
- `~/Library/Caches/`

**Linux:**
- `~/.config/`
- `~/.cache/`
- `~/.local/share/`

**All Platforms:**
- Shell configuration files (`~/.bashrc`, `~/.zshrc`, `~/.profile`)

### Package Manager Issues

If packages aren't detected:

```bash
# macOS (Homebrew)
brew list | grep -E "(clawdbot|molbot|openclaw)"

# Ubuntu/Debian
dpkg -l | grep -E "(clawdbot|molbot|openclaw)"

# Fedora/RHEL
dnf list installed | grep -E "(clawdbot|molbot|openclaw)"

# npm
npm list -g --depth=0 | grep -E "(clawdbot|molbot|openclaw)"

# pip
pip list | grep -E "(clawdbot|molbot|openclaw)"
```

Then manually uninstall:

```bash
# Homebrew
brew uninstall <package-name>

# APT
sudo apt remove <package-name>

# npm
npm uninstall -g <package-name>

# pip
pip uninstall <package-name>
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

### Areas for Contribution

- Support for additional package managers
- Windows support (PowerShell version)
- Enhanced orphaned file detection
- Improved backup/restore functionality

## License

MIT License - See [LICENSE](LICENSE) file for details

## Disclaimer

This is an unofficial uninstaller script. It is not affiliated with or endorsed by the developers of Clawdbot, Molbot, or OpenClaw.

**Use at your own risk.** While this script creates backups and has been tested, always ensure you have your own backups before running system modification scripts.

## Related Projects

- [Clawdbot](https://github.com/clawdbot/clawdbot)
- [Molbot](https://github.com/molbot/molbot)
- [OpenClaw](https://openclaw.ai/)

## Support

For issues, questions, or suggestions:
- Open an issue on [GitHub Issues](https://github.com/adibirzu/clawdbot-uninstaller/issues)
- Check existing issues for solutions

---

**Note**: This script uses standard product uninstall capabilities through package managers where available, but also performs comprehensive checks for missing packages and orphaned files that may remain after incomplete installations, updates, or manual removals.
