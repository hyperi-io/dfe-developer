#!/usr/bin/env bash
# Verify that a --profile developer install did NOT leak Hyperi-specific
# tooling. Run on a fresh VM post-install.

set -euo pipefail

FAIL=0
check_absent() {
    local name="$1" cmd="$2"
    if eval "$cmd" >/dev/null 2>&1; then
        echo "FAIL: $name is present (should not be in developer tier)"
        FAIL=1
    else
        echo "OK:   $name absent"
    fi
}

# Hyperi-specific packages
check_absent "slack-desktop"         "dpkg -l slack-desktop 2>/dev/null | grep -q '^ii'"
check_absent "slack (rpm)"           "rpm -q slack 2>/dev/null"
check_absent "linear-cli binary"     "command -v linear"
check_absent "jfrog cli binary"      "command -v jf"
check_absent "rclone binary"         "command -v rclone"
check_absent "wireguard-tools"       "dpkg -l wireguard-tools 2>/dev/null | grep -q '^ii'"
check_absent "wireguard-tools (rpm)" "rpm -q wireguard-tools 2>/dev/null"
check_absent "openvpn3"              "command -v openvpn3"

# Hyperi branding leak — wallpaper.yml copies to /usr/local/share/backgrounds/
check_absent "hyperi background"     "test -f /usr/local/share/backgrounds/background.svg"

if [[ $FAIL -ne 0 ]]; then
    echo ""
    echo "OSS-safe check FAILED — Hyperi tooling leaked into developer tier."
    exit 1
fi
echo "OSS-safe check PASSED."
