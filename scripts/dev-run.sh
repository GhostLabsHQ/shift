#!/bin/bash
# Build, (optionally) sign with a stable identity, and run Shift.
#
# Why: the SwiftPM debug binary is ad-hoc signed, so macOS ties the Accessibility
# grant to the binary's content hash — every rebuild loses the permission. Signing
# with a stable self-signed certificate makes the grant survive rebuilds.
#
# One-time setup for persistent permission:
#   1. Open Keychain Access → menu: Keychain Access → Certificate Assistant →
#      Create a Certificate…
#   2. Name: "shift-dev"   Identity Type: Self Signed Root
#      Certificate Type: Code Signing   → Create.
#   3. export SHIFT_SIGN_ID="shift-dev"   (add to your ~/.zshrc to make it stick)
#
# Then: ./scripts/dev-run.sh
# Without SHIFT_SIGN_ID it still runs, but you'll re-grant Accessibility per rebuild.

set -e
cd "$(dirname "$0")/.."

swift build
BIN=".build/debug/Shift"

if [ -n "$SHIFT_SIGN_ID" ]; then
    echo "==> Signing $BIN as app.shift.Shift with identity '$SHIFT_SIGN_ID'"
    codesign --force --identifier app.shift.Shift --sign "$SHIFT_SIGN_ID" "$BIN"
else
    echo "==> No SHIFT_SIGN_ID set: using ad-hoc signature."
    echo "    Accessibility permission will NOT survive rebuilds (see header for setup)."
fi

# Stop any previous instance so the new launch re-reads the trust state.
pkill -f "$BIN" 2>/dev/null || true
sleep 0.3

echo "==> Launching Shift. Grant Accessibility if prompted; the menu shows status."
exec "$BIN"
