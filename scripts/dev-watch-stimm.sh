#!/usr/bin/env bash
# dev-watch-stimm.sh — Watch @stimm/protocol for changes and auto-rebuild.
# Run this in a dedicated terminal while developing.
#
# After each rebuild, the gateway needs a restart to pick up the new dist:
#   Ctrl+C on the gateway → pnpm openclaw gateway run --port 18789
#
# Usage:
#   ./scripts/dev-watch-stimm.sh

set -euo pipefail

STIMM_PROTOCOL_DIR="/home/etienne/repos/stimm/packages/protocol-ts"

echo "==> Watching @stimm/protocol for changes..."
echo "    After each rebuild: Ctrl+C on the gateway → pnpm openclaw gateway run --port 18789"
echo "    (Ctrl+C to stop)"
echo ""

exec npm --prefix "${STIMM_PROTOCOL_DIR}" run dev
