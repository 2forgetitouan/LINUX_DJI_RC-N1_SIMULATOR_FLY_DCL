#!/usr/bin/env bash

set -uo pipefail

C_RESET="\033[0m"
C_GREEN="\033[1;32m"
C_RED="\033[1;31m"
C_YELLOW="\033[1;33m"
C_BLUE="\033[1;34m"

info()  { echo -e "${C_BLUE}[*]${C_RESET} $*"; }
ok()    { echo -e "${C_GREEN}[OK]${C_RESET} $*"; }
warn()  { echo -e "${C_YELLOW}[!]${C_RESET} $*"; }
fail()  { echo -e "${C_RED}[ERROR]${C_RESET} $*"; }

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VENV_DIR="$SCRIPT_DIR/.venv"
MAIN_PY="$SCRIPT_DIR/main.py"
UDEV_RULE_PATH="/etc/udev/rules.d/99-uinput.rules"
UDEV_RULE_CONTENT='KERNEL=="uinput", MODE="0660", GROUP="input", OPTIONS+="static_node=uinput"'

REQUIRED_GROUPS=("dialout" "input")
REBOOT_NEEDED=0

if [ ! -f "$MAIN_PY" ]; then
    fail "main.py not found in $SCRIPT_DIR. Place this script next to main.py."
    exit 1
fi

info "Checking Python environment..."

if ! command -v python3 >/dev/null 2>&1; then
    fail "python3 is not installed. Install it with: sudo dnf install python3"
    exit 1
fi

if [ ! -d "$VENV_DIR" ]; then
    info "No virtual environment found, creating .venv..."
    python3 -m venv "$VENV_DIR"
fi

# shellcheck disable=SC1091
source "$VENV_DIR/bin/activate"

MISSING_DEPS=0
python3 -c "import serial" >/dev/null 2>&1 || MISSING_DEPS=1
python3 -c "import evdev" >/dev/null 2>&1 || MISSING_DEPS=1

if [ "$MISSING_DEPS" -eq 1 ]; then
    info "Installing missing dependencies (pyserial, evdev)..."
    pip install --upgrade pip -q
    if ! pip install pyserial evdev -q; then
        fail "Failed to install Python dependencies."
        deactivate
        exit 1
    fi
fi
ok "Python dependencies satisfied."

info "Checking user groups..."

CURRENT_USER="$(whoami)"
SESSION_GROUPS="$(id -nG "$CURRENT_USER")"

for grp in "${REQUIRED_GROUPS[@]}"; do
    if ! getent group "$grp" >/dev/null 2>&1; then
        sudo groupadd "$grp"
    fi

    if id -nG "$CURRENT_USER" | grep -qw "$grp"; then
        if ! echo "$SESSION_GROUPS" | grep -qw "$grp"; then
            warn "Group '$grp' is assigned but not active in this session."
            REBOOT_NEEDED=1
        fi
    else
        info "Adding '$CURRENT_USER' to group '$grp'..."
        sudo usermod -aG "$grp" "$CURRENT_USER"
        REBOOT_NEEDED=1
    fi
done

ok "Group requirements checked (dialout, input)."

info "Checking udev rule for /dev/uinput..."

if [ ! -f "$UDEV_RULE_PATH" ] || ! grep -qF "$UDEV_RULE_CONTENT" "$UDEV_RULE_PATH" 2>/dev/null; then
    echo "$UDEV_RULE_CONTENT" | sudo tee "$UDEV_RULE_PATH" >/dev/null
    sudo udevadm control --reload-rules
    sudo udevadm trigger
    sudo modprobe -r uinput 2>/dev/null
    sudo modprobe uinput
    ok "udev rule applied, uinput module reloaded."
else
    ok "udev rule already in place."
fi

if [ ! -f /etc/modules-load.d/uinput.conf ]; then
    echo "uinput" | sudo tee /etc/modules-load.d/uinput.conf >/dev/null
fi

if [ -e /dev/uinput ]; then
    DEV_GROUP="$(stat -c '%G' /dev/uinput)"
    DEV_MODE="$(stat -c '%a' /dev/uinput)"
    if [ "$DEV_GROUP" != "input" ] || [ "$DEV_MODE" != "660" ]; then
        warn "/dev/uinput permissions not yet correct (group=$DEV_GROUP mode=$DEV_MODE)."
        REBOOT_NEEDED=1
    fi
else
    warn "/dev/uinput does not exist yet. A reboot should create it correctly."
    REBOOT_NEEDED=1
fi

if [ -e /dev/uinput ] && [ ! -w /dev/uinput ]; then
    warn "No write access to /dev/uinput in this session."
    REBOOT_NEEDED=1
fi

if [ "$REBOOT_NEEDED" -eq 1 ]; then
    echo
    warn "Permission changes were applied (groups and/or udev rules)."
    warn "A reboot is required for them to take full effect."
    echo
    read -r -p "Reboot now? [y/N] " REPLY
    case "$REPLY" in
        [yY]*)
            info "Rebooting..."
            deactivate 2>/dev/null
            sudo reboot
            ;;
        *)
            warn "Reboot skipped. Re-run this script after rebooting manually (sudo reboot)."
            deactivate 2>/dev/null
            exit 0
            ;;
    esac
else
    ok "All checks passed: dependencies and permissions are in order."
    clear
    exec python3 "$MAIN_PY"
fi
