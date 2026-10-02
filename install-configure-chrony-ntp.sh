#!/usr/bin/env bash
#
# install-configure-chrony-ntp.sh
# Installs and configures chrony on Ubuntu with:
#   - primary NTP server: 10.4.20.12 (preferred) - replace with your local server IP
#   - backup NTP pool:    ntp.pagasa.dost.gov.ph
#
# Usage: sudo ./install-configure-chrony-ntp.sh
#
set -euo pipefail

PRIMARY_SERVER="10.4.20.12"
BACKUP_POOL="ntp.pagasa.dost.gov.ph"
CHRONY_CONF="/etc/chrony/chrony.conf"
TIMESTAMP="$(date +%Y%m%d-%H%M%S)"

if [[ $EUID -ne 0 ]]; then
    echo "This script must be run as root (use sudo)." >&2
    exit 1
fi

echo "==> Step 1: Installing chrony (if not already present)..."
apt update
apt install -y chrony

if [[ ! -f "$CHRONY_CONF" ]]; then
    echo "Error: $CHRONY_CONF not found after install. Aborting." >&2
    exit 1
fi

echo "==> Step 2: Backing up existing config to ${CHRONY_CONF}.bak.${TIMESTAMP}"
cp -a "$CHRONY_CONF" "${CHRONY_CONF}.bak.${TIMESTAMP}"

echo "==> Step 3: Removing default pool/server lines and adding our servers..."
# Comment out any existing active (non-comment) pool/server lines instead of deleting,
# so the original config is still visible/auditable in the file.
sed -i -E 's/^(pool|server)\s+/# &/' "$CHRONY_CONF"

# Avoid duplicate entries if the script is re-run.
if ! grep -qF "server ${PRIMARY_SERVER} iburst prefer" "$CHRONY_CONF"; then
    {
        echo ""
        echo "# --- Added by install-configure-chrony-ntp.sh on ${TIMESTAMP} ---"
        echo "server ${PRIMARY_SERVER} iburst prefer"
        echo "pool ${BACKUP_POOL} iburst"
    } >> "$CHRONY_CONF"
fi

echo "==> Step 4: 'prefer' biases chrony toward ${PRIMARY_SERVER} when both sources are reachable and healthy."

echo "==> Step 5: Restarting and enabling chrony..."
systemctl restart chrony
systemctl enable chrony

echo "==> Step 6: Verifying sync (allow a few seconds to settle)..."
sleep 5
echo "--- chronyc sources -v ---"
chronyc sources -v || true
echo ""
echo "--- chronyc tracking ---"
chronyc tracking || true

echo ""
echo "==> Done. Confirm above that ${PRIMARY_SERVER} is marked with '*' (current sync source) and has a low offset."
echo "    Config backup saved at: ${CHRONY_CONF}.bak.${TIMESTAMP}"
