#!/usr/bin/env bash
# dev-link.sh — Active le mode dev : symlinks + arrêt du service systemd.
#
# Ce script fait :
#   1. Arrête le service openclaw-gateway systemd (libère le port 18789)
#   2. Build @stimm/protocol depuis les sources
#   3. Symlink node_modules/@stimm/protocol → stimm/packages/protocol-ts
#   4. Symlink ~/.openclaw/extensions/stimm-voice → ce repo
#
# Ensuite, pour débuguer :
#   cd /home/etienne/repos/openclaw && pnpm openclaw gateway run --port 18789
#
# ┌──────────────────────────────────────────────────────────────────────┐
# │  Tu as modifié...          │  Ce que tu fais                         │
# ├──────────────────────────────────────────────────────────────────────┤
# │  plugin (index.ts/html)    │  Ctrl+C  →  pnpm openclaw gateway run   │
# │  stimm (protocol-ts/src)   │  npm run build  →  Ctrl+C  →  relancer  │
# │  openclaw core (src/)      │  Ctrl+C  →  pnpm openclaw gateway run   │
# │                            │  (pnpm rebuild auto si dist/ est stale) │
# └──────────────────────────────────────────────────────────────────────┘
#
# Undo : ./scripts/dev-unlink.sh

set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
STIMM_PROTOCOL_DIR="/home/etienne/repos/stimm/packages/protocol-ts"
EXTENSIONS_DIR="${HOME}/.openclaw/extensions"
EXTENSION_INSTALL="${EXTENSIONS_DIR}/stimm-voice"

echo "==> [dev-link] Plugin dir:   ${PLUGIN_DIR}"
echo "==> [dev-link] Protocol dir: ${STIMM_PROTOCOL_DIR}"
echo "==> [dev-link] Install dir:  ${EXTENSION_INSTALL}"
echo ""

# --------------------------------------------------------------------------
# 1. Build @stimm/protocol (dist/ must exist before symlinking)
# --------------------------------------------------------------------------
echo "==> [dev-link] Building @stimm/protocol..."
(cd "${STIMM_PROTOCOL_DIR}" && npm run build)
echo "    ✓ @stimm/protocol built"

# --------------------------------------------------------------------------
# 2. Symlink @stimm/protocol inside this repo's node_modules
# --------------------------------------------------------------------------
PLUGIN_STIMM_NM="${PLUGIN_DIR}/node_modules/@stimm/protocol"

# Ensure node_modules/@stimm exists
mkdir -p "${PLUGIN_DIR}/node_modules/@stimm"

if [ -L "${PLUGIN_STIMM_NM}" ]; then
  echo "==> [dev-link] @stimm/protocol symlink already present, re-pointing..."
  rm "${PLUGIN_STIMM_NM}"
elif [ -d "${PLUGIN_STIMM_NM}" ]; then
  echo "==> [dev-link] Backing up existing node_modules/@stimm/protocol..."
  mv "${PLUGIN_STIMM_NM}" "${PLUGIN_STIMM_NM}.npm-backup"
fi

ln -s "${STIMM_PROTOCOL_DIR}" "${PLUGIN_STIMM_NM}"
echo "    ✓ node_modules/@stimm/protocol → ${STIMM_PROTOCOL_DIR}"

# --------------------------------------------------------------------------
# 3. Replace installed plugin with a symlink to this repo
# --------------------------------------------------------------------------
if [ -L "${EXTENSION_INSTALL}" ]; then
  echo "==> [dev-link] Plugin install is already a symlink, re-pointing..."
  rm "${EXTENSION_INSTALL}"
elif [ -d "${EXTENSION_INSTALL}" ]; then
  echo "==> [dev-link] Backing up existing plugin install..."
  mv "${EXTENSION_INSTALL}" "${EXTENSION_INSTALL}.npm-backup"
fi

ln -s "${PLUGIN_DIR}" "${EXTENSION_INSTALL}"
echo "    ✓ ${EXTENSION_INSTALL} → ${PLUGIN_DIR}"

# --------------------------------------------------------------------------
# 4. Arrêt du service systemd (libère le port 18789 pour pnpm openclaw)
# --------------------------------------------------------------------------
echo "==> [dev-link] Arrêt du service openclaw-gateway systemd..."
if systemctl --user is-active --quiet openclaw-gateway; then
  systemctl --user stop openclaw-gateway
  echo "    ✓ Service arrêté"
else
  echo "    (service déjà arrêté)"
fi

echo ""
echo "✅  Mode dev actif. Lance le gateway avec :"
echo ""
echo "    cd /home/etienne/repos/openclaw"
echo "    pnpm openclaw gateway run --port 18789"
echo ""
echo "┌──────────────────────────────────────────────────────────────────────┐"
echo "│  Tu as modifié...          │  Ce que tu fais                         │"
echo "├──────────────────────────────────────────────────────────────────────┤"
echo "│  plugin (index.ts/html)    │  Ctrl+C  →  pnpm openclaw gateway run   │"
echo "│  stimm (protocol-ts/src)   │  npm run build  →  Ctrl+C  →  relancer  │"
echo "│  openclaw core (src/)      │  Ctrl+C  →  pnpm openclaw gateway run   │"
echo "│                            │  (pnpm rebuild auto si dist/ est stale) │"
echo "└──────────────────────────────────────────────────────────────────────┘"
echo ""
echo "    Quand tu as fini : ./scripts/dev-unlink.sh"
