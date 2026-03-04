#!/usr/bin/env bash
# dev-unlink.sh — Restore production npm packages and remove all dev symlinks.
#
# Usage:
#   ./scripts/dev-unlink.sh

set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STIMM_PROTOCOL_DIR="/home/etienne/repos/stimm/packages/protocol-ts"
EXTENSIONS_DIR="${HOME}/.openclaw/extensions"
EXTENSION_INSTALL="${EXTENSIONS_DIR}/stimm-voice"

echo "==> [dev-unlink] Restoring npm packages..."
echo ""

# --------------------------------------------------------------------------
# 1. Restore installed plugin
# --------------------------------------------------------------------------
if [ -L "${EXTENSION_INSTALL}" ]; then
  echo "==> [dev-unlink] Removing plugin symlink..."
  rm "${EXTENSION_INSTALL}"

  if [ -d "${EXTENSION_INSTALL}.npm-backup" ]; then
    echo "==> [dev-unlink] Restoring npm backup..."
    mv "${EXTENSION_INSTALL}.npm-backup" "${EXTENSION_INSTALL}"
    echo "    ✓ Restored from backup"
  else
    echo "==> [dev-unlink] No backup found — reinstalling from npm..."
    openclaw plugins install openclaw-stimm-voice
    echo "    ✓ Reinstalled from npm"
  fi
else
  echo "    (plugin install is not a symlink — nothing to restore)"
fi

# --------------------------------------------------------------------------
# 2. Restore @stimm/protocol in plugin node_modules
# --------------------------------------------------------------------------
PLUGIN_STIMM_NM="${PLUGIN_DIR}/node_modules/@stimm/protocol"

if [ -L "${PLUGIN_STIMM_NM}" ]; then
  echo "==> [dev-unlink] Removing @stimm/protocol symlink..."
  rm "${PLUGIN_STIMM_NM}"

  if [ -d "${PLUGIN_STIMM_NM}.npm-backup" ]; then
    echo "==> [dev-unlink] Restoring @stimm/protocol npm backup..."
    mv "${PLUGIN_STIMM_NM}.npm-backup" "${PLUGIN_STIMM_NM}"
    echo "    ✓ Restored from backup"
  else
    echo "==> [dev-unlink] No backup found — running npm install..."
    (cd "${PLUGIN_DIR}" && npm install)
    echo "    ✓ npm install done"
  fi
else
  echo "    (@stimm/protocol is not a symlink — nothing to restore)"
fi

# --------------------------------------------------------------------------
# 3. Redémarrage du service systemd
# --------------------------------------------------------------------------
echo ""
echo "==> [dev-unlink] Redémarrage du service openclaw-gateway..."
systemctl --user start openclaw-gateway
echo "    ✓ Service redémarré (npm, port 18789)"

echo ""
echo "✅  Mode production restauré. Le plugin charge depuis npm."
