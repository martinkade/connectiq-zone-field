#!/usr/bin/env bash
# ==============================================================================
# ZoneField - Simulator Build & Run Helper Script
# ==============================================================================
# Usage:
#   ./build_sim.sh [device]       # Build .prg for specific device (default: edge1040)
#   ./build_sim.sh [device] run   # Build and launch in simulator
# ==============================================================================

set -euo pipefail

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

DEVICE="${1:-edge1040}"
RUN_SIM="${2:-}"

OUTPUT_DIR="$PROJECT_DIR/bin"
OUTPUT_PRG="$OUTPUT_DIR/ZoneField.prg"
KEY_FILE="$PROJECT_DIR/developer_key.der"
JUNGLE_FILE="$PROJECT_DIR/monkey.jungle"

# SDK discovery
CFG_FILE="$HOME/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg"
if [ -f "$CFG_FILE" ]; then
    SDK_ROOT="$(cat "$CFG_FILE" | tr -d '\r\n')"
else
    SDK_ROOT="$(find "$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks" -maxdepth 1 -type d -name "connectiq-sdk-*" 2>/dev/null | sort -V | tail -n 1 || true)"
fi

MB_JAR="$SDK_ROOT/bin/monkeybrains.jar"
SIM_BIN="$SDK_ROOT/bin/connectiq"
MONKEYDO="$SDK_ROOT/bin/monkeydo"

mkdir -p "$OUTPUT_DIR"

echo "Building ZoneField for $DEVICE..."
java -Xms1g -Dfile.encoding=UTF-8 -Dapple.awt.UIElement=true \
    -jar "$MB_JAR" \
    -o "$OUTPUT_PRG" \
    -f "$JUNGLE_FILE" \
    -y "$KEY_FILE" \
    -d "$DEVICE" \
    -w

echo "Build successful: $OUTPUT_PRG"

if [ "$RUN_SIM" = "run" ] || [ "${1:-}" = "run" ]; then
    echo "Starting simulator..."
    "$SIM_BIN" &
    sleep 2
    "$MONKEYDO" "$OUTPUT_PRG" "$DEVICE"
fi
