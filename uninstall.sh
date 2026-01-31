#!/bin/bash

# Uninstall script for clawdbot, molbot, and openclaw
# Supports: macOS and Linux
#
# This script uses the product's standard uninstall capabilities where available,
# but also performs comprehensive checks for missing packages and orphaned files
# that may remain after incomplete installations or updates.

set -e

# Detect OS
OS="$(uname -s)"
case "${OS}" in
    Darwin*)    PLATFORM="macos";;
    Linux*)     PLATFORM="linux";;
    *)          echo "Unsupported operating system: ${OS}"; exit 1;;
esac

echo "================================================"
echo "Clawdbot, Molbot, and OpenClaw Uninstaller"
echo "Platform: ${PLATFORM}"
echo "================================================"
echo ""

# Function to print colored output
print_status() {
    echo -e "\033[1;34m[*]\033[0m $1"
}

print_success() {
    echo -e "\033[1;32m[✓]\033[0m $1"
}

print_error() {
    echo -e "\033[1;31m[✗]\033[0m $1"
}

print_warning() {
    echo -e "\033[1;33m[!]\033[0m $1"
}

# Check if running with appropriate permissions
if [ "$EUID" -eq 0 ]; then
    print_error "Please do not run this script as root/sudo"
    print_status "The script will request sudo when needed"
    exit 1
fi

echo "This script will:"
echo "  1. Create a backup of all config files and skills"
echo "  2. Remove all clawdbot, molbot, and openclaw processes"
echo "  3. Remove data directories"
echo "  4. Remove service files (LaunchAgents/systemd units)"
echo "  5. Remove executables and package installations"
echo "  6. Check for missing/orphaned packages"
echo ""
read -p "Do you want to continue? (y/N): " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Uninstall cancelled."
    exit 0
fi

# Create backup directory
if [ "${PLATFORM}" = "macos" ]; then
    BACKUP_DIR=~/Desktop/clawdbot-molbot-openclaw-backup-$(date +%Y%m%d-%H%M%S)
else
    BACKUP_DIR=~/clawdbot-molbot-openclaw-backup-$(date +%Y%m%d-%H%M%S)
fi

print_status "Creating backup at: $BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# Backup function
backup_if_exists() {
    local source="$1"
    local dest_name="$2"

    if [ -e "$source" ]; then
        cp -R "$source" "$BACKUP_DIR/$dest_name" 2>/dev/null && print_success "Backed up: $dest_name" || print_error "Failed to backup: $dest_name"
        return 0
    fi
    return 1
}

# Backup configuration files and skills
print_status "Backing up configuration files and skills..."

# Backup entire config directories (preserving structure)
for app in clawdbot molbot openclaw; do
    if [ -d ~/.$app ]; then
        mkdir -p "$BACKUP_DIR/$app"

        # Common config subdirectories
        for subdir in settings credentials identity agents skills config; do
            backup_if_exists ~/.$app/$subdir "$app/$subdir"
        done

        # Backup common config files
        for config_file in exec-approvals.json config.json settings.json; do
            backup_if_exists ~/.$app/$config_file "$app/$config_file"
        done

        # Backup any remaining config files
        find ~/.$app -maxdepth 2 \( -name "*.json" -o -name "*.yaml" -o -name "*.yml" -o -name "*.conf" -o -name "*.toml" \) 2>/dev/null | while read -r config; do
            rel_path=$(echo "$config" | sed "s|$HOME/.$app/||")
            backup_if_exists "$config" "$app/$rel_path"
        done
    fi
done

# Create a backup info file
cat > "$BACKUP_DIR/README.txt" << EOF
Backup created on: $(date)
Platform: ${PLATFORM}
Hostname: $(hostname)
User: $(whoami)

This backup contains configuration files and skills from:
- clawdbot
- molbot
- openclaw

To restore, manually copy the files back to their original locations:
- clawdbot files go to ~/.clawdbot/
- molbot files go to ~/.molbot/
- openclaw files go to ~/.openclaw/

Original uninstall script: $0
EOF

print_success "Backup completed at: $BACKUP_DIR"
echo ""

# 1. Stop and kill running processes
print_status "Stopping running processes..."

# Kill Chrome/Chromium processes using these apps
pkill -f ".clawdbot/browser" 2>/dev/null && print_success "Killed clawdbot Chrome processes" || print_status "No clawdbot Chrome processes found"
pkill -f ".openclaw/browser" 2>/dev/null && print_success "Killed openclaw Chrome processes" || print_status "No openclaw Chrome processes found"
pkill -f ".molbot/browser" 2>/dev/null && print_success "Killed molbot Chrome processes" || print_status "No molbot Chrome processes found"

# Kill application-specific processes
for process in moltbot-gateway molbot clawdbot clawd openclaw; do
    if pkill -f "$process" 2>/dev/null; then
        print_success "Killed $process processes"
    else
        print_status "No $process processes found"
    fi
done

sleep 2

# 2. Platform-specific service management
if [ "${PLATFORM}" = "macos" ]; then
    print_status "Checking for LaunchAgents and LaunchDaemons..."

    # User LaunchAgents
    for plist in ~/Library/LaunchAgents/*clawdbot* ~/Library/LaunchAgents/*molbot* ~/Library/LaunchAgents/*clawd* ~/Library/LaunchAgents/*openclaw*; do
        if [ -f "$plist" ]; then
            launchctl unload "$plist" 2>/dev/null && print_success "Unloaded $(basename $plist)"
            rm "$plist" && print_success "Removed $(basename $plist)"
        fi
    done

    # System-wide LaunchAgents/Daemons (requires sudo)
    if [ -n "$(find /Library/LaunchAgents /Library/LaunchDaemons -name '*clawdbot*' -o -name '*molbot*' -o -name '*clawd*' -o -name '*openclaw*' 2>/dev/null)" ]; then
        print_status "Found system-wide LaunchAgents/Daemons. Attempting to remove (may require sudo)..."
        for plist in /Library/LaunchAgents/*clawdbot* /Library/LaunchAgents/*molbot* /Library/LaunchAgents/*clawd* /Library/LaunchAgents/*openclaw* /Library/LaunchDaemons/*clawdbot* /Library/LaunchDaemons/*molbot* /Library/LaunchDaemons/*clawd* /Library/LaunchDaemons/*openclaw*; do
            if [ -f "$plist" ]; then
                sudo launchctl unload "$plist" 2>/dev/null && print_success "Unloaded $(basename $plist)"
                sudo rm "$plist" && print_success "Removed $(basename $plist)"
            fi
        done
    fi
elif [ "${PLATFORM}" = "linux" ]; then
    print_status "Checking for systemd services..."

    # User systemd services
    for service in clawdbot molbot openclaw clawd; do
        if systemctl --user list-unit-files | grep -q "$service"; then
            systemctl --user stop "$service" 2>/dev/null && print_success "Stopped $service service"
            systemctl --user disable "$service" 2>/dev/null && print_success "Disabled $service service"
        fi
    done

    # Remove user service files
    for service_file in ~/.config/systemd/user/*clawdbot* ~/.config/systemd/user/*molbot* ~/.config/systemd/user/*openclaw* ~/.config/systemd/user/*clawd*; do
        if [ -f "$service_file" ]; then
            rm "$service_file" && print_success "Removed $(basename $service_file)"
        fi
    done

    # System-wide services (requires sudo)
    for service in clawdbot molbot openclaw clawd; do
        if systemctl list-unit-files 2>/dev/null | grep -q "$service"; then
            print_status "Found system service: $service (requires sudo)"
            sudo systemctl stop "$service" 2>/dev/null && print_success "Stopped $service service"
            sudo systemctl disable "$service" 2>/dev/null && print_success "Disabled $service service"
        fi
    done

    # Remove system service files
    for service_file in /etc/systemd/system/*clawdbot* /etc/systemd/system/*molbot* /etc/systemd/system/*openclaw* /etc/systemd/system/*clawd*; do
        if [ -f "$service_file" ]; then
            sudo rm "$service_file" && print_success "Removed $(basename $service_file)"
        fi
    done

    systemctl --user daemon-reload 2>/dev/null || true
    sudo systemctl daemon-reload 2>/dev/null || true
fi

# 3. Remove data directories
print_status "Removing data directories..."

for app in clawdbot molbot openclaw; do
    if [ -d ~/.$app ]; then
        rm -rf ~/.$app && print_success "Removed ~/.$app directory"
    else
        print_status "~/.$app directory not found"
    fi
done

# 4. Remove executables
print_status "Checking for executables..."

# Common binary locations
if [ "${PLATFORM}" = "macos" ]; then
    BINARY_LOCATIONS=("/usr/local/bin" "$HOME/.local/bin" "$HOME/bin" "/opt/homebrew/bin")
else
    BINARY_LOCATIONS=("/usr/local/bin" "$HOME/.local/bin" "$HOME/bin" "/usr/bin" "/opt")
fi

for location in "${BINARY_LOCATIONS[@]}"; do
    if [ ! -d "$location" ]; then
        continue
    fi

    for binary in clawdbot molbot clawd moltbot-gateway openclaw; do
        if [ -f "$location/$binary" ]; then
            if [ -w "$location/$binary" ]; then
                rm "$location/$binary" && print_success "Removed $location/$binary"
            else
                sudo rm "$location/$binary" && print_success "Removed $location/$binary (required sudo)"
            fi
        fi
    done
done

# 5. Platform-specific package management
if [ "${PLATFORM}" = "macos" ]; then
    print_status "Checking Homebrew installations..."
    if command -v brew &> /dev/null; then
        if brew list 2>/dev/null | grep -qE "(clawdbot|molbot|openclaw)"; then
            brew list | grep -E "(clawdbot|molbot|openclaw)" | while read -r formula; do
                brew uninstall "$formula" && print_success "Uninstalled $formula via Homebrew"
            done
        else
            print_status "No Homebrew packages found"
        fi
    else
        print_status "Homebrew not installed, skipping"
    fi
elif [ "${PLATFORM}" = "linux" ]; then
    print_status "Checking system package managers..."

    # APT (Debian/Ubuntu)
    if command -v apt &> /dev/null; then
        for pkg in clawdbot molbot openclaw; do
            if dpkg -l | grep -q "^ii.*$pkg"; then
                print_status "Found APT package: $pkg (requires sudo)"
                sudo apt remove -y "$pkg" && print_success "Removed $pkg via APT"
            fi
        done
    fi

    # DNF/YUM (Fedora/RHEL/CentOS)
    if command -v dnf &> /dev/null; then
        for pkg in clawdbot molbot openclaw; do
            if dnf list installed 2>/dev/null | grep -q "$pkg"; then
                print_status "Found DNF package: $pkg (requires sudo)"
                sudo dnf remove -y "$pkg" && print_success "Removed $pkg via DNF"
            fi
        done
    elif command -v yum &> /dev/null; then
        for pkg in clawdbot molbot openclaw; do
            if yum list installed 2>/dev/null | grep -q "$pkg"; then
                print_status "Found YUM package: $pkg (requires sudo)"
                sudo yum remove -y "$pkg" && print_success "Removed $pkg via YUM"
            fi
        done
    fi

    # Pacman (Arch Linux)
    if command -v pacman &> /dev/null; then
        for pkg in clawdbot molbot openclaw; do
            if pacman -Q "$pkg" 2>/dev/null; then
                print_status "Found Pacman package: $pkg (requires sudo)"
                sudo pacman -R --noconfirm "$pkg" && print_success "Removed $pkg via Pacman"
            fi
        done
    fi

    # Snap
    if command -v snap &> /dev/null; then
        for pkg in clawdbot molbot openclaw; do
            if snap list 2>/dev/null | grep -q "$pkg"; then
                print_status "Found Snap package: $pkg (requires sudo)"
                sudo snap remove "$pkg" && print_success "Removed $pkg via Snap"
            fi
        done
    fi

    # Flatpak
    if command -v flatpak &> /dev/null; then
        for pkg in clawdbot molbot openclaw; do
            if flatpak list 2>/dev/null | grep -q "$pkg"; then
                print_status "Found Flatpak package: $pkg"
                flatpak uninstall -y "$pkg" && print_success "Removed $pkg via Flatpak"
            fi
        done
    fi
fi

# 6. Clean up npm global packages (cross-platform)
print_status "Checking npm global packages..."
if command -v npm &> /dev/null; then
    npm list -g --depth=0 2>/dev/null | grep -E "(clawdbot|molbot|openclaw)" | awk '{print $2}' | cut -d'@' -f1 | while read -r package; do
        npm uninstall -g "$package" && print_success "Uninstalled $package via npm"
    done
else
    print_status "npm not found, skipping"
fi

# 7. Remove any remaining files in common locations
print_status "Searching for remaining files and orphaned packages..."

if [ "${PLATFORM}" = "macos" ]; then
    SEARCH_DIRS=("/Applications" "/usr/local/share" "$HOME/Library/Application Support" "$HOME/Library/Caches")
else
    SEARCH_DIRS=("/opt" "/usr/share" "/usr/local/share" "$HOME/.config" "$HOME/.cache" "$HOME/.local/share")
fi

for dir in "${SEARCH_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        find "$dir" -maxdepth 3 \( -name "*clawdbot*" -o -name "*molbot*" -o -name "*clawd*" -o -name "*openclaw*" \) 2>/dev/null | while read -r file; do
            if [ -e "$file" ]; then
                print_warning "Found orphaned file: $file"
                read -p "  Remove this? (y/N): " -n 1 -r
                echo ""
                if [[ $REPLY =~ ^[Yy]$ ]]; then
                    if [ -w "$file" ] || [ -w "$(dirname "$file")" ]; then
                        rm -rf "$file" && print_success "Removed $file"
                    else
                        sudo rm -rf "$file" && print_success "Removed $file (required sudo)"
                    fi
                fi
            fi
        done
    fi
done

# 8. Check for Python packages
print_status "Checking Python packages..."
if command -v pip &> /dev/null || command -v pip3 &> /dev/null; then
    PIP_CMD=$(command -v pip3 || command -v pip)
    $PIP_CMD list 2>/dev/null | grep -E "(clawdbot|molbot|openclaw)" | awk '{print $1}' | while read -r package; do
        $PIP_CMD uninstall -y "$package" && print_success "Uninstalled $package via pip"
    done
else
    print_status "pip not found, skipping"
fi

# 9. Clean up shell configurations
print_status "Checking shell configuration files..."
for shell_rc in ~/.bashrc ~/.zshrc ~/.profile ~/.bash_profile; do
    if [ -f "$shell_rc" ]; then
        if grep -qE "(clawdbot|molbot|openclaw|clawd)" "$shell_rc" 2>/dev/null; then
            print_warning "Found references in $shell_rc"
            print_status "Please manually review and remove any PATH or alias entries"
        fi
    fi
done

echo ""
echo "======================================"
print_success "Uninstall complete!"
echo "======================================"
echo ""
echo "Summary:"
echo "  - Backup created at: $BACKUP_DIR"
echo "  - All processes stopped"
echo "  - Data directories removed"
echo "  - Configuration files removed"
echo "  - Service files removed"
echo "  - Package installations removed"
echo ""
echo "Your configuration files and skills have been backed up."
echo "You can find them at: $BACKUP_DIR"
echo ""
if [ "${PLATFORM}" = "macos" ]; then
    echo "If you experience any issues, please manually check:"
    echo "  - ~/Library/Application Support/"
    echo "  - ~/Library/Preferences/"
    echo "  - ~/Library/Caches/"
else
    echo "If you experience any issues, please manually check:"
    echo "  - ~/.config/"
    echo "  - ~/.cache/"
    echo "  - ~/.local/share/"
fi
echo ""
echo "Please review your shell configuration files (~/.bashrc, ~/.zshrc)"
echo "and remove any PATH entries or aliases related to these applications."
echo ""
