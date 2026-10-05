#!/usr/bin/env bash
# ==============================================================================
# ZoneField - Garmin Connect IQ Build & Release Deployment Script
# ==============================================================================
# Builds an upload-ready application bundle (.iq file) for the Garmin Connect IQ Store.
# ==============================================================================

set -euo pipefail

# ANSI Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}======================================================${NC}"
echo -e "${BLUE}    Garmin Connect IQ - ZoneField Release Packager    ${NC}"
echo -e "${BLUE}======================================================${NC}"

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$PROJECT_DIR"

OUTPUT_DIR="$PROJECT_DIR/bin"
OUTPUT_BUNDLE="$OUTPUT_DIR/ZoneField.iq"
KEY_FILE="$PROJECT_DIR/developer_key.der"
JUNGLE_FILE="$PROJECT_DIR/monkey.jungle"
MANIFEST_FILE="$PROJECT_DIR/manifest.xml"

# 1. Verify Developer Key
if [ ! -f "$KEY_FILE" ]; then
    echo -e "${RED}[ERROR] Developer key not found at $KEY_FILE${NC}"
    echo -e "Generate one with:"
    echo -e "  openssl genrsa -out developer_key.pem 4096"
    echo -e "  openssl pkcs8 -topk8 -inform PEM -outform DER -in developer_key.pem -out developer_key.der -nocrypt"
    exit 1
fi
echo -e "${GREEN}[✓] Developer Key found:${NC} $KEY_FILE"

# 2. Locate Garmin Connect IQ SDK
SDK_ROOT=""
CFG_FILE="$HOME/Library/Application Support/Garmin/ConnectIQ/current-sdk.cfg"

if [ -n "${GARMIN_SDK_PATH:-}" ] && [ -d "$GARMIN_SDK_PATH" ]; then
    SDK_ROOT="$GARMIN_SDK_PATH"
elif [ -f "$CFG_FILE" ]; then
    SDK_ROOT="$(cat "$CFG_FILE" | tr -d '\r\n')"
fi

if [ -z "$SDK_ROOT" ] || [ ! -d "$SDK_ROOT" ]; then
    # Try finding latest SDK directory
    SDK_CANDIDATE="$(find "$HOME/Library/Application Support/Garmin/ConnectIQ/Sdks" -maxdepth 1 -type d -name "connectiq-sdk-*" 2>/dev/null | sort -V | tail -n 1 || true)"
    if [ -n "$SDK_CANDIDATE" ] && [ -d "$SDK_CANDIDATE" ]; then
        SDK_ROOT="$SDK_CANDIDATE"
    fi
fi

if [ -z "$SDK_ROOT" ] || [ ! -d "$SDK_ROOT" ]; then
    echo -e "${RED}[ERROR] Connect IQ SDK not found.${NC}"
    echo -e "Please open Connect IQ SDK Manager and ensure an SDK is installed."
    exit 1
fi

MB_JAR="$SDK_ROOT/bin/monkeybrains.jar"
if [ ! -f "$MB_JAR" ]; then
    echo -e "${RED}[ERROR] monkeybrains.jar not found in $SDK_ROOT/bin${NC}"
    exit 1
fi
echo -e "${GREEN}[✓] Using SDK:${NC} $SDK_ROOT"

# 3. Locate Java
JAVA_BIN="java"
if [ -n "${JAVA_HOME:-}" ] && [ -x "$JAVA_HOME/bin/java" ]; then
    JAVA_BIN="$JAVA_HOME/bin/java"
elif [ -x "/usr/libexec/java_home" ]; then
    SYS_JAVA_HOME="$(/usr/libexec/java_home 2>/dev/null || true)"
    if [ -n "$SYS_JAVA_HOME" ] && [ -x "$SYS_JAVA_HOME/bin/java" ]; then
        JAVA_BIN="$SYS_JAVA_HOME/bin/java"
    fi
fi

# Verify Java is callable
if ! "$JAVA_BIN" -version >/dev/null 2>&1; then
    echo -e "${RED}[ERROR] Java is not accessible via '$JAVA_BIN'.${NC}"
    echo -e "Please install OpenJDK 17/21 or ensure JAVA_HOME is configured."
    exit 1
fi
JAVA_VER="$("$JAVA_BIN" -version 2>&1 | head -n 1)"
echo -e "${GREEN}[✓] Java runtime:${NC} $JAVA_VER"

# 4. Prepare output folder
mkdir -p "$OUTPUT_DIR"
rm -f "$OUTPUT_BUNDLE"

# 5. Build .iq Application Bundle
echo -e "\n${YELLOW}[BUILD] Compiling & Packaging .iq release bundle...${NC}"

# Flags:
#  -e               Export as Connect IQ application bundle (.iq)
#  -f               Jungle file defining project manifest and sources
#  -o               Output file path
#  -y               Private developer key for signing
#  -r               Release build (optimizations enabled)
#  -w               Show compiler warnings
"$JAVA_BIN" -Xms1g -Dfile.encoding=UTF-8 -Dapple.awt.UIElement=true \
    -jar "$MB_JAR" \
    -e \
    -f "$JUNGLE_FILE" \
    -o "$OUTPUT_BUNDLE" \
    -y "$KEY_FILE" \
    -r \
    -w

# 6. Verify result
if [ -f "$OUTPUT_BUNDLE" ]; then
    BUNDLE_SIZE="$(du -h "$OUTPUT_BUNDLE" | cut -f1)"
    echo -e "\n${GREEN}======================================================${NC}"
    echo -e "${GREEN}  ✓ SUCCESS: Application bundle created successfully! ${NC}"
    echo -e "${GREEN}======================================================${NC}"
    echo -e "File: ${BLUE}$OUTPUT_BUNDLE${NC} (${BUNDLE_SIZE})"
    
    echo -e "\nPackaged Target Devices:"
    grep '<iq:product id=' "$MANIFEST_FILE" | sed -E 's/.*id="([^"]+)".*/  • \1/'

    echo -e "\n${YELLOW}Next Steps:${NC}"
    echo -e "1. Go to the Garmin Connect IQ Developer Dashboard:"
    echo -e "   ${BLUE}https://apps.garmin.com/developer/dashboard${NC}"
    echo -e "2. Click 'Upload an App' and upload ${BLUE}$OUTPUT_BUNDLE${NC}"
    echo -e "3. Fill in your store listing description, screenshots, and submit!\n"
else
    echo -e "\n${RED}[ERROR] Build finished but $OUTPUT_BUNDLE was not found.${NC}"
    exit 1
fi
